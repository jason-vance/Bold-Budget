//
//  BudgetsListBudgetsProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/24/24.
//

import Foundation
import Combine

class BudgetsListBudgetsProvider {
    
    let budgetsPublisher: CurrentValueSubject<[BudgetInfo]?,Never> = .init(nil)
    
    private var userId: UserId? = nil
    
    private let budgetsProvider: BudgetsProvider
    private var userIdSub: AnyCancellable? = nil
    private var budgetsSub: AnyCancellable? = nil
    
    init(
        userIdProvider: CurrentUserIdProvider,
        budgetsProvider: BudgetsProvider
    ) {
        self.budgetsProvider = budgetsProvider
        
        userIdSub = userIdProvider.currentUserIdPublisher
            .sink(receiveValue: getBudgetsPublisher(for:))
    }
    
    private func getBudgetsPublisher(for userId: UserId?) {
        guard self.userId != userId else { return }
        
        budgetsSub = nil
        self.userId = userId
        budgetsPublisher.send(nil)

        if let userId = userId {
            budgetsSub = budgetsProvider
                .getBudgetsPublisher(for: userId)
                .sink { [weak self] in self?.budgetsPublisher.send($0) }
        }
    }
}
