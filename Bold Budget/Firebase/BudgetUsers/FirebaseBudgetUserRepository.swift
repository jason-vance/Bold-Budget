//
//  FirebaseBudgetUserRepository.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/26/24.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseBudgetUserRepository {
    
    static let USERS = "Users"
    
    func usersCollection(in budget: BudgetInfo) -> CollectionReference {
        Firestore.firestore()
            .collection(FirebaseBudgetRepository.BUDGETS)
            .document(budget.id)
            .collection(Self.USERS)
    }

    func add(user userId: UserId, as role: Budget.User.Role, to budget: BudgetInfo) async throws {
        let doc = FirebaseBudgetUserDoc.from(user: .init(id: userId, role: role))
        try await usersCollection(in: budget).document(userId.value).setData(from: doc)
    }
}

extension FirebaseBudgetUserRepository: BudgetUserFetcher {
    func fetchUsers(in budget: BudgetInfo) async throws -> [Budget.User] {
        try await usersCollection(in: budget)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: FirebaseBudgetUserDoc.self).toBudgetUser() }
    }
}
