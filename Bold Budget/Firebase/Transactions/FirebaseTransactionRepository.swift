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
    
    private let intDateField = FirebaseTransactionDoc.CodingKeys.intDate.rawValue
    
    func transactionsCollection(in budget: BudgetInfo) -> CollectionReference {
        Firestore.firestore()
            .collection(FirebaseBudgetRepository.BUDGETS)
            .document(budget.id)
            .collection(Self.TRANSACTIONS)
    }
}

extension FirebaseTransactionRepository: TransactionSaver {
    func save(transaction: Transaction, to budget: BudgetInfo) async throws {
        let doc = FirebaseTransactionDoc.from(transaction)
        try await transactionsCollection(in: budget)
            .document(transaction.id.uuidString)
            .setData(from: doc)
    }
}

extension FirebaseTransactionRepository: TransactionFetcher {
    func fetchTransactions(
        in budget: BudgetInfo
    ) async throws -> [Transaction] {
        return try await transactionsCollection(in: budget)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: FirebaseTransactionDoc.self).toTransaction() }
    }
}

extension FirebaseTransactionRepository: TransactionDeleter {
    func delete(transaction: Transaction, from budget: BudgetInfo) async throws {
        try await transactionsCollection(in: budget)
            .document(transaction.id.uuidString)
            .delete()
    }
}
