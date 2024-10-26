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
    
    func categoriesCollection(in budget: Budget) -> CollectionReference {
        Firestore.firestore()
            .collection(FirebaseBudgetsRepository.BUDGETS)
            .document(budget.id)
            .collection(Self.TRANSACTION_CATEGORIES)
    }

    func listenToTransactionCategories(
        in budget: Budget,
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

extension FirebaseTransactionCategoryRepository: TransactionCategorySaver {
    
    func save(category: Transaction.Category, to budget: Budget) async throws {
        let doc = FirebaseTransactionCategoryDoc.from(category)
        try await categoriesCollection(in: budget).document(category.id).setData(from: doc)
    }
}
