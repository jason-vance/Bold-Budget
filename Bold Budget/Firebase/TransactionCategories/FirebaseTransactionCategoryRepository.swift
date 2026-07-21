//
//  FirebaseTransactionCategoryRepository.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/25/24.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseTransactionCategoryRepository {
    
    static let TRANSACTION_CATEGORIES = "TransactionCategories"
    
    func categoriesCollection(in budget: BudgetInfo) -> CollectionReference {
        Firestore.firestore()
            .collection(FirebaseBudgetRepository.BUDGETS)
            .document(budget.id)
            .collection(Self.TRANSACTION_CATEGORIES)
    }
}

extension FirebaseTransactionCategoryRepository: TransactionCategoryFetcher {
    func fetchTransactionCategories(in budget: BudgetInfo) async throws -> [Transaction.Category] {
        try await categoriesCollection(in: budget)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: FirebaseTransactionCategoryDoc.self).toCategory() }
    }

    func fetchLegacyCategoryKinds(in budget: BudgetInfo) async throws -> [Transaction.Category.Id: Transaction.Kind] {
        let docs = try await categoriesCollection(in: budget)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: FirebaseTransactionCategoryDoc.self) }

        return docs.reduce(into: [:]) { result, doc in
            guard let idString = doc.id,
                  let id = Transaction.Category.Id(uuidString: idString),
                  let kind = doc.legacyKind() else { return }
            result[id] = kind
        }
    }
}

extension FirebaseTransactionCategoryRepository: TransactionCategorySaver {
    func save(category: Transaction.Category, to budget: BudgetInfo) async throws {
        let doc = FirebaseTransactionCategoryDoc.from(category)
        try await categoriesCollection(in: budget)
            .document(category.id.uuidString)
            .setData(from: doc)
    }
}

extension FirebaseTransactionCategoryRepository: TransactionCategoryDeleter {
    func delete(category: Transaction.Category, from budget: BudgetInfo) async throws {
        try await categoriesCollection(in: budget)
            .document(category.id.uuidString)
            .delete()
    }
}
