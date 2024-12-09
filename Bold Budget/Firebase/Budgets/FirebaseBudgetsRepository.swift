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
    
    let usersField = FirebaseBudgetDoc.CodingKeys.users.rawValue

    //TODO: Change to a simple fetch
    func getBudgetsPublisher(
        for userId: UserId,
        onUpdate: @escaping ([BudgetInfo]) -> (),
        onError: @escaping (Error) -> ()
    ) -> AnyCancellable {
        let listener = budgetsCollection
            .whereField(usersField, arrayContains: userId.value)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    onError(error ?? TextError("Unknown Error listening to budgets"))
                    return
                }

                let budgets = snapshot.documents
                    .compactMap { try? $0.data(as: FirebaseBudgetDoc.self).toBudget() }
                onUpdate(budgets)
            }
        
        return .init({ listener.remove() })
    }
}

extension FirebaseBudgetsRepository: BudgetCreator {
    func create(budget: BudgetInfo, ownedBy userId: UserId) async throws {
        let usersRepo = FirebaseBudgetUsersRepository()
        try await usersRepo.add(user: userId, as: .owner, to: budget)
        
        //TODO: Set the fields directly like in updateUserDocument()
        //TODO: Do an array union thing with the budget.users property
        let doc = FirebaseBudgetDoc.from(budget)
        try await budgetsCollection.document(budget.id).setData(from: doc)
    }
}
