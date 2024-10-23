//
//  BudgetSaver.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/23/24.
//

import Foundation

protocol BudgetSaver {
    func save(budget: Budget) async throws
}

class MockBudgetSaver: BudgetSaver {
    
    let throwing: Bool
    
    init(throwing: Bool) {
        self.throwing = throwing
    }
    
    func save(budget: Budget) async throws {
        try await Task.sleep(for: .seconds(0.5))
        if throwing { throw TextError("MockBudgetSaver.throwing") }
    }
}

extension MockBudgetSaver {

    private static let envKey_TestThrowing: String = "MockBudgetSaver.envKey_TestThrowing"
    
    public static func test(throwing: Bool, in environment: inout [String:String]) {
        environment[envKey_TestThrowing] = String(throwing)
    }
    
    static func getTestInstance() -> MockBudgetSaver? {
        guard let throwingStr = ProcessInfo.processInfo.environment[envKey_TestThrowing] else { return nil }
        guard let throwing = Bool(throwingStr) else { return nil }
        return .init(throwing: throwing)
    }
}

