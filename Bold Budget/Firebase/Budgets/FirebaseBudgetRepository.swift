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
        let usersRepo = FirebaseBudgetUsersRepository()
        try await usersRepo.add(user: userId, as: .owner, to: budget)
        
        //TODO: Set the fields directly like in updateUserDocument()
        //TODO: Do an array union thing with the budget.users property
        let doc = FirebaseBudgetDoc.from(budget)
        try await budgetsCollection.document(budget.id).setData(from: doc)
    }
}
