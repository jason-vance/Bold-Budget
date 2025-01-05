//
//  BudgetDeleter.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/4/25.
//

import Foundation

protocol BudgetDeleter {
    func delete(budget: BudgetInfo) async throws
}

class MockBudgetDeleter: BudgetDeleter {
    
    var errorToThrow: Error? = nil
    
    init(errorToThrow: Error? = nil) {
        self.errorToThrow = errorToThrow
    }
    
    func delete(budget: BudgetInfo) async throws {
        if let errorToThrow { throw errorToThrow }
    }
}

extension MockBudgetDeleter {

    private static let envKey_TestThrowing: String = "MockBudgetDeleter.envKey_TestThrowing"
    
    public static func test(throwing: Bool, in environment: inout [String:String]) {
        environment[envKey_TestThrowing] = String(throwing)
    }
    
    static func getTestInstance() -> MockBudgetDeleter? {
        guard let doesThrowString = ProcessInfo.processInfo.environment[envKey_TestThrowing] else { return nil }
        guard let doesThrow = Bool(doesThrowString) else { return nil }
        return .init(errorToThrow: doesThrow ? TextError("MockBudgetDeleter.testError") : nil)
    }
}
