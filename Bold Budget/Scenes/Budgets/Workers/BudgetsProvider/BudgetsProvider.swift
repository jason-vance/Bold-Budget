//
//  BudgetProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/20/24.
//

import Foundation
import Combine

protocol BudgetsProvider {
    func getBudgetsPublisher(for: UserId) -> AnyPublisher<[BudgetInfo]?,Never>
}

class MockBudgetsProvider: BudgetsProvider {
    
    let budgets: [BudgetInfo]
    var userId: UserId? = nil
    var subject: CurrentValueSubject<[BudgetInfo]?,Never>? = nil
    
    init(budgets: [BudgetInfo]) {
        self.budgets = budgets
    }
    
    func getBudgetsPublisher(for userId: UserId) -> AnyPublisher<[BudgetInfo]?, Never> {
        if self.userId != userId {
            self.userId = userId
            
            subject = CurrentValueSubject<[BudgetInfo]?,Never>(nil)
            
            Task {
                try await Task.sleep(for: .seconds(0.5))
                subject?.send(budgets)
            }
        }
        
        return subject!.eraseToAnyPublisher()
    }
}

extension MockBudgetsProvider {

    private static let envKey_TestUsingSample: String = "MockBudgetProvider.envKey_TestUsingSample"
    
    public static func test(usingSample: Bool, in environment: inout [String:String]) {
        environment[envKey_TestUsingSample] = String(usingSample)
    }
    
    static func getTestInstance() -> MockBudgetsProvider? {
        guard let useSampleStr = ProcessInfo.processInfo.environment[envKey_TestUsingSample] else { return nil }
        guard let useSample = Bool(useSampleStr) else { return nil }
        return .init(budgets: useSample ? [.sample] : [])
    }
}
