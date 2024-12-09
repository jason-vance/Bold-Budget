//
//  BudgetFetcher.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/20/24.
//

import Foundation
import Combine

protocol BudgetFetcher {
    func fetchBudgets(
        for userId: UserId
    ) async throws -> [BudgetInfo]
}

class MockBudgetFetcher: BudgetFetcher {
    
    let budgets: [BudgetInfo]
    
    init(budgets: [BudgetInfo] = [.sample]) {
        self.budgets = budgets
    }
    
    func fetchBudgets(
        for userId: UserId
    ) async throws -> [BudgetInfo] {
        return budgets
    }
}

extension MockBudgetFetcher {

    private static let envKey_TestUsingSample: String = "MockBudgetFetcher.envKey_TestUsingSample"
    
    public static func test(usingSample: Bool, in environment: inout [String:String]) {
        environment[envKey_TestUsingSample] = String(usingSample)
    }
    
    static func getTestInstance() -> MockBudgetFetcher? {
        guard let useSampleStr = ProcessInfo.processInfo.environment[envKey_TestUsingSample] else { return nil }
        guard let useSample = Bool(useSampleStr) else { return nil }
        return .init(budgets: useSample ? [.sample] : [])
    }
}
