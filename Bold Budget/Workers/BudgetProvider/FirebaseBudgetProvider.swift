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
    
    private let budgetsSubject: CurrentValueSubject<[Budget]?,Never>
    private let budgetsPublisher: AnyPublisher<[Budget]?,Never>

    private var userId: UserId? = nil
    private var listener: AnyCancellable? = nil
    
    init() {
        budgetsSubject = CurrentValueSubject<[Budget]?,Never>(nil)
        budgetsPublisher = budgetsSubject.eraseToAnyPublisher()
    }
    
    func getBudgetsPublisher(for userId: UserId) -> AnyPublisher<[Budget]?, Never> {
        if userId != self.userId {
            self.userId = userId
            
            budgetsSubject.send(nil)
            
            listener = budgetRepo.getBudgetsPublisher(
                for: userId,
                onUpdate: onUpdate(budgets:),
                onError: onError
            )
        }
        
        return budgetsPublisher
    }
    
    private func onUpdate(budgets: [Budget]) {
        budgetsSubject.send(budgets)
    }
    
    private func onError(_ error: Error) {
        print("FirebaseBudgetProvider: Error listening to budgets. \(error.localizedDescription)")
    }
}
