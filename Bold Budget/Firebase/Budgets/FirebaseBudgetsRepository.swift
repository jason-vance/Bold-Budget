//
//  FirebaseBudgetsRepository.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/22/24.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseBudgetsRepository {
    
    static let BUDGETS = "Budgets"
    
    let budgetsCollection = Firestore.firestore().collection(BUDGETS)
    
    let ownerField = FirebaseBudgetDoc.CodingKeys.owner.rawValue

    func getBudgetsPublisher(
        for userId: UserId,
        onUpdate: @escaping ([Budget]) -> (),
        onError: @escaping (Error) -> ()
    ) -> AnyCancellable {
        let listener = budgetsCollection
            .whereField(ownerField, isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    onError(error ?? TextError("Unknown Error listening to budgets"))
                    return
                }
                
                let budgets = snapshot.documents
                    .compactMap {
                        try? $0.data(as: FirebaseBudgetDoc.self).toBudget()
                    }
                onUpdate(budgets)
            }
        
        return .init({ listener.remove() })
    }
}
