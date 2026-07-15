//
//  RecurringExpenseSaver.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/15/26.
//

import Foundation

protocol RecurringExpenseSaver {
    func save(recurringExpense: RecurringExpense, to budget: BudgetInfo) async throws
}

class MockRecurringExpenseSaver: RecurringExpenseSaver {

    var willThrow: Bool = false

    func save(recurringExpense: RecurringExpense, to budget: BudgetInfo) async throws {
        if willThrow { throw TextError("MockRecurringExpenseSaver.TestError") }
    }
}

extension MockRecurringExpenseSaver {
    private static let envKey_TestWillThrow: String = "MockRecurringExpenseSaver.envKey_TestWillThrow"

    public static func test(willThrow: Bool, in environment: inout [String:String]) {
        environment[envKey_TestWillThrow] = String(describing: willThrow)
    }

    static func getTestInstance() -> MockRecurringExpenseSaver? {
        guard let willThrowString = ProcessInfo.processInfo.environment[envKey_TestWillThrow] else { return nil }
        guard let willThrow = Bool(willThrowString) else { return nil }

        let mock = MockRecurringExpenseSaver()
        mock.willThrow = willThrow
        return mock
    }
}
