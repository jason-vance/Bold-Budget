//
//  FirebaseTransactionRepository.swift
//  Bold Budget
//
//  Created by Jason Vance on 11/28/24.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseTransactionRepository {
    
    static let TRANSACTIONS = "Transactions"
    
    func transactionsCollection(in budget: Budget) -> CollectionReference {
        Firestore.firestore()
            .collection(FirebaseBudgetsRepository.BUDGETS)
            .document(budget.id)
            .collection(Self.TRANSACTIONS)
    }
}

extension FirebaseTransactionRepository: TransactionSaver {
    func save(transaction: Transaction, to budget: Budget) async throws {
        let doc = FirebaseTransactionDoc.from(transaction)
        try await transactionsCollection(in: budget).document(transaction.id).setData(from: doc)
    }
}
