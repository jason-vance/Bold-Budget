//
//  BudgetUserRemover.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation

protocol BudgetUserRemover {
    /// Removes a user from the budget. Passing the current user is how "leave budget" works.
    func remove(user userId: UserId, from budget: BudgetInfo) async throws
}

class MockBudgetUserRemover: BudgetUserRemover {

    let throwing: Bool

    init(throwing: Bool = false) {
        self.throwing = throwing
    }

    func remove(user userId: UserId, from budget: BudgetInfo) async throws {
        try await Task.sleep(for: .seconds(0.5))
        if throwing { throw TextError("MockBudgetUserRemover.throwing") }
    }
}

extension MockBudgetUserRemover {

    private static let envKey_TestThrowing: String = "MockBudgetUserRemover.envKey_TestThrowing"

    public static func test(throwing: Bool, in environment: inout [String:String]) {
        environment[envKey_TestThrowing] = String(throwing)
    }

    static func getTestInstance() -> MockBudgetUserRemover? {
        guard let throwingStr = ProcessInfo.processInfo.environment[envKey_TestThrowing] else { return nil }
        guard let throwing = Bool(throwingStr) else { return nil }
        return .init(throwing: throwing)
    }
}
