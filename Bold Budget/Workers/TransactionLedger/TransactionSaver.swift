//
//  TransactionSaver.swift
//  Bold Budget
//
//  Created by Jason Vance on 11/28/24.
//

import Foundation

protocol TransactionSaver {
    func save(transaction: Transaction, to budget: Budget) async throws
}

class MockTransactionSaver: TransactionSaver {
    
    var willThrow: Bool = false
    
    func save(transaction: Transaction, to budget: Budget) async throws {
        if willThrow { throw TextError("MockTransactionSaver.TestError") }
    }
}

extension MockTransactionSaver {
    private static let envKey_TestWillThrow: String = "MockTransactionSaver.envKey_TestWillThrow"
    
    public static func test(willThrow: Bool, in environment: inout [String:String]) {
        environment[envKey_TestWillThrow] = String(describing: willThrow)
    }
    
    static func getTestInstance() -> MockTransactionSaver? {
        guard let willThrowString = ProcessInfo.processInfo.environment[envKey_TestWillThrow] else { return nil }
        guard let willThrow = Bool(willThrowString) else { return nil }
        
        let mock = MockTransactionSaver()
        mock.willThrow = willThrow
        return mock
    }
}
