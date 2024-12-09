//
//  TransactionDeleter.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/8/24.
//

import Foundation

protocol TransactionDeleter {
    func delete(transaction: Transaction, from budget: BudgetInfo) async throws
}

class MockTransactionDeleter: TransactionDeleter {
    
    var willThrow: Bool = false
    
    func delete(transaction: Transaction, from budget: BudgetInfo) async throws {
        if willThrow { throw TextError("MockTransactionDeleter.TestError") }
    }
}

extension MockTransactionDeleter {
    private static let envKey_TestWillThrow: String = "MockTransactionDeleter.envKey_TestWillThrow"
    
    public static func test(willThrow: Bool, in environment: inout [String:String]) {
        environment[envKey_TestWillThrow] = String(describing: willThrow)
    }
    
    static func getTestInstance() -> MockTransactionDeleter? {
        guard let willThrowString = ProcessInfo.processInfo.environment[envKey_TestWillThrow] else { return nil }
        guard let willThrow = Bool(willThrowString) else { return nil }
        
        let mock = MockTransactionDeleter()
        mock.willThrow = willThrow
        return mock
    }
}
