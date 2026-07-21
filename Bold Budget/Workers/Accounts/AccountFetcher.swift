//
//  AccountFetcher.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/21/26.
//

import Foundation

protocol AccountFetcher {
    func fetchAccounts(in budget: BudgetInfo) async throws -> [Account]
}

class MockAccountFetcher: AccountFetcher {

    var accounts: [Account] = []
    var error: Error? = nil

    func fetchAccounts(in budget: BudgetInfo) async throws -> [Account] {
        if let error = error {
            throw error
        }
        return accounts
    }
}

extension MockAccountFetcher {

    public enum TestCategory: String, RawRepresentable {
        case empty
        case samples
        case error
    }

    private static let envKey_TestCategory: String = "MockAccountFetcher.envKey_TestCategory"

    public static func test(using category: TestCategory, in environment: inout [String:String]) {
        environment[envKey_TestCategory] = String(describing: category)
    }

    static func getTestInstance() -> MockAccountFetcher? {
        guard let categoryString = ProcessInfo.processInfo.environment[envKey_TestCategory] else { return nil }
        guard let category = TestCategory(rawValue: categoryString) else { return nil }

        let mock = MockAccountFetcher()
        switch category {
        case .empty:
            mock.accounts = []
        case .samples:
            mock.accounts = Account.samples
        case .error:
            mock.error = TextError("MockAccountFetcher.TestError")
        }
        return mock
    }
}
