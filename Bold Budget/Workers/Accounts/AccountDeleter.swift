//
//  AccountDeleter.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/21/26.
//

import Foundation

protocol AccountDeleter {
    func delete(account: Account, from budget: BudgetInfo) async throws
}

class MockAccountDeleter: AccountDeleter {

    var willThrow: Bool = false

    func delete(account: Account, from budget: BudgetInfo) async throws {
        if willThrow { throw TextError("MockAccountDeleter.TestError") }
    }
}

extension MockAccountDeleter {
    private static let envKey_TestWillThrow: String = "MockAccountDeleter.envKey_TestWillThrow"

    public static func test(willThrow: Bool, in environment: inout [String:String]) {
        environment[envKey_TestWillThrow] = String(describing: willThrow)
    }

    static func getTestInstance() -> MockAccountDeleter? {
        guard let willThrowString = ProcessInfo.processInfo.environment[envKey_TestWillThrow] else { return nil }
        guard let willThrow = Bool(willThrowString) else { return nil }

        let mock = MockAccountDeleter()
        mock.willThrow = willThrow
        return mock
    }
}
