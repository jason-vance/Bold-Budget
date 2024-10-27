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
    
    func usersCollection(in budget: Budget) -> CollectionReference {
        Firestore.firestore()
            .collection(FirebaseBudgetsRepository.BUDGETS)
            .document(budget.id)
            .collection(Self.USERS)
    }

    func add(user userId: UserId, as role: FirebaseBudgetUserDoc.Role, to budget: Budget) async throws {
        let doc = FirebaseBudgetUserDoc(userId: userId.value, role: role)
        try await usersCollection(in: budget).document(userId.value).setData(from: doc)
    }
}
