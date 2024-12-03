//
//  TransactionCategorySaver.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/25/24.
//

import Foundation

protocol TransactionCategorySaver {
    func save(category: Transaction.Category, to budget: BudgetInfo) async throws
}

class MockTransactionCategorySaver: TransactionCategorySaver {
    
    private let willThrow: Bool
    
    init(willThrow: Bool) {
        self.willThrow = willThrow
    }
    
    func save(category: Transaction.Category, to budget: BudgetInfo) async throws {
        try await Task.sleep(for: .seconds(0.5))
        if willThrow { throw TextError("MockTransactionCategorySaver.willThrow") }
    }
}

extension MockTransactionCategorySaver {
    
    private static let envKey_TestWillThrow: String = "MockTransactionCategorySaver.envKey_TestWillThrow"
    
    public static func test(willThrow: Bool, in environment: inout [String:String]) {
        environment[envKey_TestWillThrow] = String(willThrow)
    }
    
    static func getTestInstance() -> MockTransactionCategorySaver? {
        guard let willThrowStr = ProcessInfo.processInfo.environment[envKey_TestWillThrow] else { return nil }
        guard let willThrow = Bool(willThrowStr) else { return nil }
        return .init(willThrow: willThrow)
    }
}
