//
//  AccountSaver.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/21/26.
//

import Foundation

protocol AccountSaver {
    func save(account: Account, to budget: BudgetInfo) async throws
}

class MockAccountSaver: AccountSaver {

    var willThrow: Bool = false

    func save(account: Account, to budget: BudgetInfo) async throws {
        if willThrow { throw TextError("MockAccountSaver.TestError") }
    }
}

extension MockAccountSaver {
    private static let envKey_TestWillThrow: String = "MockAccountSaver.envKey_TestWillThrow"

    public static func test(willThrow: Bool, in environment: inout [String:String]) {
        environment[envKey_TestWillThrow] = String(describing: willThrow)
    }

    static func getTestInstance() -> MockAccountSaver? {
        guard let willThrowString = ProcessInfo.processInfo.environment[envKey_TestWillThrow] else { return nil }
        guard let willThrow = Bool(willThrowString) else { return nil }

        let mock = MockAccountSaver()
        mock.willThrow = willThrow
        return mock
    }
}
