//
//  FirebaseBudgetProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/22/24.
//

import Foundation
import Combine

class FirebaseBudgetProvider: BudgetProvider {
    
    private let budgetRepo = FirebaseBudgetsRepository()
    
    private var budgetsSubject: CurrentValueSubject<[Budget]?,Never>? = nil
    
    private var listener: AnyCancellable? = nil
    
    func getBudgetsPublisher(for userId: UserId) -> AnyPublisher<[Budget]?, Never> {
        budgetsSubject = CurrentValueSubject<[Budget]?, Never>(nil)
        
        listener = budgetRepo.getBudgetsPublisher(
            for: userId,
            onUpdate: onUpdate(budgets:),
            onError: onError
        )
        
        return budgetsSubject!.eraseToAnyPublisher()
    }
    
    private func onUpdate(budgets: [Budget]) {
        budgetsSubject?.send(budgets)
    }
    
    private func onError(_ error: Error) {
        print("FirebaseBudgetProvider: Error listening to budgets. \(error.localizedDescription)")
    }
}
