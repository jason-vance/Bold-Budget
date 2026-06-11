//
//  TransactionCategoryDeleter.swift
//  Bold Budget
//
//  Created by Jason Vance on 6/11/26.
//

import Foundation

protocol TransactionCategoryDeleter {
    func delete(category: Transaction.Category, from budget: BudgetInfo) async throws
}

class MockTransactionCategoryDeleter: TransactionCategoryDeleter {

    var errorToThrow: Error? = nil

    init(errorToThrow: Error? = nil) {
        self.errorToThrow = errorToThrow
    }

    func delete(category: Transaction.Category, from budget: BudgetInfo) async throws {
        if let errorToThrow { throw errorToThrow }
    }
}

extension MockTransactionCategoryDeleter {

    private static let envKey_TestThrowing: String = "MockTransactionCategoryDeleter.envKey_TestThrowing"

    public static func test(throwing: Bool, in environment: inout [String:String]) {
        environment[envKey_TestThrowing] = String(throwing)
    }

    static func getTestInstance() -> MockTransactionCategoryDeleter? {
        guard let doesThrowString = ProcessInfo.processInfo.environment[envKey_TestThrowing] else { return nil }
        guard let doesThrow = Bool(doesThrowString) else { return nil }
        return .init(errorToThrow: doesThrow ? TextError("MockTransactionCategoryDeleter.testError") : nil)
    }
}
