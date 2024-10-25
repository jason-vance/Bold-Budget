//
//  BudgetProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/20/24.
//

import Foundation
import Combine

protocol BudgetsProvider {
    func getBudgetsPublisher(for: UserId) -> AnyPublisher<[Budget]?,Never>
}

class MockBudgetsProvider: BudgetsProvider {
    
    let budgets: [Budget]
    var userId: UserId? = nil
    var subject: CurrentValueSubject<[Budget]?,Never>? = nil
    
    init(budgets: [Budget]) {
        self.budgets = budgets
    }
    
    func getBudgetsPublisher(for userId: UserId) -> AnyPublisher<[Budget]?, Never> {
        if self.userId != userId {
            self.userId = userId
            
            subject = CurrentValueSubject<[Budget]?,Never>(nil)
            
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
