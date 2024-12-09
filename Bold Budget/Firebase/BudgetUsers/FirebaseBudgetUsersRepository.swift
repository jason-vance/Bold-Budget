//
//  FirebaseBudgetUsersRepository.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/26/24.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseBudgetUsersRepository {
    
    static let USERS = "Users"
    
    func usersCollection(in budget: BudgetInfo) -> CollectionReference {
        Firestore.firestore()
            .collection(FirebaseBudgetRepository.BUDGETS)
            .document(budget.id)
            .collection(Self.USERS)
    }

    func add(user userId: UserId, as role: FirebaseBudgetUserDoc.Role, to budget: BudgetInfo) async throws {
        let doc = FirebaseBudgetUserDoc(userId: userId.value, role: role)
        try await usersCollection(in: budget).document(userId.value).setData(from: doc)
    }
}
