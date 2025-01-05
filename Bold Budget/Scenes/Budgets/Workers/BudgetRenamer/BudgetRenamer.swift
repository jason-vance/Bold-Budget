//
//  BudgetRenamer.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/4/25.
//

import Foundation

protocol BudgetRenamer {
    func rename(budget: Budget, to: BudgetInfo.Name) async throws
}

class MockBudgetRenamer: BudgetRenamer {
    
    var errorToThrow: Error? = nil
    
    init(errorToThrow: Error? = nil) {
        self.errorToThrow = errorToThrow
    }
    
    func rename(budget: Budget, to: BudgetInfo.Name) async throws {
        if let errorToThrow { throw errorToThrow }
    }
}

extension MockBudgetRenamer {

    private static let envKey_TestThrowing: String = "MockBudgetRenamer.envKey_TestThrowing"
    
    public static func test(throwing: Bool, in environment: inout [String:String]) {
        environment[envKey_TestThrowing] = String(throwing)
    }
    
    static func getTestInstance() -> MockBudgetRenamer? {
        guard let doesThrowString = ProcessInfo.processInfo.environment[envKey_TestThrowing] else { return nil }
        guard let doesThrow = Bool(doesThrowString) else { return nil }
        return .init(errorToThrow: doesThrow ? TextError("MockBudgetRenamer.testError") : nil)
    }
}
