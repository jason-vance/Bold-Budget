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

    //TODO: Remove this listener version and just use fetch
    func listenToTransactionCategories(
        in budget: BudgetInfo,
        onUpdate: @escaping ([Transaction.Category]) -> (),
        onError: @escaping (Error) -> ()
    ) -> AnyCancellable {
        let listener = categoriesCollection(in: budget)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    onError(error ?? TextError("Unknown Error listening to transaction categories"))
                    return
                }
                
                let categories = snapshot.documents
                    .compactMap {
                        try? $0.data(as: FirebaseTransactionCategoryDoc.self).toCategory()
                    }
                onUpdate(categories)
            }
        
        return .init({ listener.remove() })
    }
}

extension FirebaseTransactionCategoryRepository: TransactionCategoryFetcher {
    func fetchTransactionCategories(in budget: BudgetInfo) async throws -> [Transaction.Category] {
        try await categoriesCollection(in: budget)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: FirebaseTransactionCategoryDoc.self).toCategory() }
    }
}

extension FirebaseTransactionCategoryRepository: TransactionCategorySaver {
    func save(category: Transaction.Category, to budget: BudgetInfo) async throws {
        let doc = FirebaseTransactionCategoryDoc.from(category)
        try await categoriesCollection(in: budget).document(category.id).setData(from: doc)
    }
}
