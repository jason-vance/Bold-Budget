//
//  RecurringExpenseDeleter.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/15/26.
//

import Foundation

protocol RecurringExpenseDeleter {
    func delete(recurringExpense: RecurringExpense, from budget: BudgetInfo) async throws
}

class MockRecurringExpenseDeleter: RecurringExpenseDeleter {

    var willThrow: Bool = false

    func delete(recurringExpense: RecurringExpense, from budget: BudgetInfo) async throws {
        if willThrow { throw TextError("MockRecurringExpenseDeleter.TestError") }
    }
}

extension MockRecurringExpenseDeleter {
    private static let envKey_TestWillThrow: String = "MockRecurringExpenseDeleter.envKey_TestWillThrow"

    public static func test(willThrow: Bool, in environment: inout [String:String]) {
        environment[envKey_TestWillThrow] = String(describing: willThrow)
    }

    static func getTestInstance() -> MockRecurringExpenseDeleter? {
        guard let willThrowString = ProcessInfo.processInfo.environment[envKey_TestWillThrow] else { return nil }
        guard let willThrow = Bool(willThrowString) else { return nil }

        let mock = MockRecurringExpenseDeleter()
        mock.willThrow = willThrow
        return mock
    }
}
