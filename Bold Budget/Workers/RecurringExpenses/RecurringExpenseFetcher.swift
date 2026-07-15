//
//  RecurringExpenseFetcher.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/15/26.
//

import Foundation

protocol RecurringExpenseFetcher {
    func fetchRecurringExpenses(in budget: BudgetInfo) async throws -> [RecurringExpense]
}

class MockRecurringExpenseFetcher: RecurringExpenseFetcher {

    var recurringExpenses: [RecurringExpense] = []
    var error: Error? = nil

    func fetchRecurringExpenses(in budget: BudgetInfo) async throws -> [RecurringExpense] {
        if let error = error {
            throw error
        }
        return recurringExpenses
    }
}

extension MockRecurringExpenseFetcher {

    public enum TestCategory: String, RawRepresentable {
        case empty
        case samples
        case error
    }

    private static let envKey_TestCategory: String = "MockRecurringExpenseFetcher.envKey_TestCategory"

    public static func test(using category: TestCategory, in environment: inout [String:String]) {
        environment[envKey_TestCategory] = String(describing: category)
    }

    static func getTestInstance() -> MockRecurringExpenseFetcher? {
        guard let categoryString = ProcessInfo.processInfo.environment[envKey_TestCategory] else { return nil }
        guard let category = TestCategory(rawValue: categoryString) else { return nil }

        let mock = MockRecurringExpenseFetcher()
        switch category {
        case .empty:
            mock.recurringExpenses = []
        case .samples:
            mock.recurringExpenses = RecurringExpense.samples
        case .error:
            mock.error = TextError("MockRecurringExpenseFetcher.TestError")
        }
        return mock
    }
}
