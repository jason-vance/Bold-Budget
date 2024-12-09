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
            .collection(FirebaseBudgetsRepository.BUDGETS)
            .document(budget.id)
            .collection(Self.TRANSACTIONS)
    }
}

extension FirebaseTransactionRepository: TransactionSaver {
    func save(transaction: Transaction, to budget: BudgetInfo) async throws {
        let doc = FirebaseTransactionDoc.from(transaction)
        try await transactionsCollection(in: budget).document(transaction.id).setData(from: doc)
    }
}

extension FirebaseTransactionRepository: TransactionFetcher {
    //TODO: Make a better version of this that doesn't fetch every single transaction
    func fetchTransactions(
        in budget: BudgetInfo
    ) async throws -> [Transaction] {
        let categoryDict = try await {
            let categoryRepo = FirebaseTransactionCategoryRepository()
            let categories = try await categoryRepo.fetchTransactionCategories(in: budget)
            return Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        }()
        
        return try await transactionsCollection(in: budget)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: FirebaseTransactionDoc.self).toTransaction(categoryDict: categoryDict) }
    }
}

extension FirebaseTransactionRepository: TransactionDeleter {
    func delete(transaction: Transaction, from budget: BudgetInfo) async throws {
        try await transactionsCollection(in: budget)
            .document(transaction.id)
            .delete()
    }
}
