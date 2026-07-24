//
//  FirebaseBudgetRepository.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/22/24.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseBudgetRepository {
    
    static let BUDGETS = "Budgets"
    
    let budgetsCollection = Firestore.firestore().collection(BUDGETS)
    
    let usersField = FirebaseBudgetDoc.CodingKeys.users.rawValue
}

extension FirebaseBudgetRepository: BudgetFetcher {
    func fetchBudgets(
        for userId: UserId
    ) async throws -> [BudgetInfo] {
        try await budgetsCollection
            .whereField(usersField, arrayContains: userId.value)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: FirebaseBudgetDoc.self).toBudget() }
    }
}

extension FirebaseBudgetRepository: BudgetCreator {
    func create(budget: BudgetInfo, ownedBy userId: UserId) async throws {
        let usersRepo = FirebaseBudgetUserRepository()
        try await usersRepo.add(user: userId, as: .owner, to: budget)
        
        let doc = FirebaseBudgetDoc.from(budget)
        try await budgetsCollection.document(budget.id).setData(from: doc)
    }
}

extension FirebaseBudgetRepository: BudgetRenamer {
    func rename(budget: Budget, to name: BudgetInfo.Name) async throws {
        try await budgetsCollection.document(budget.id).updateData([
            FirebaseBudgetDoc.CodingKeys.name.rawValue: name.value
        ])
    }
}

extension FirebaseBudgetRepository: BudgetDeleter {
    func delete(budget: BudgetInfo) async throws {
        try await budgetsCollection.document(budget.id).delete()
    }
}

extension FirebaseBudgetRepository: BudgetUserRemover {
    func remove(user userId: UserId, from budget: BudgetInfo) async throws {
        let batch = Firestore.firestore().batch()

        let budgetRef = budgetsCollection.document(budget.id)
        batch.updateData(
            [usersField: FieldValue.arrayRemove([userId.value])],
            forDocument: budgetRef
        )

        let memberRef = budgetRef
            .collection(FirebaseBudgetUserRepository.USERS)
            .document(userId.value)
        batch.deleteDocument(memberRef)

        try await batch.commit()
    }
}
