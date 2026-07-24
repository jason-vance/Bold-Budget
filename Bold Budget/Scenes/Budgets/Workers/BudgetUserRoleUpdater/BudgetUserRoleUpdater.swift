//
//  BudgetUserRoleUpdater.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/24/26.
//

import Foundation

protocol BudgetUserRoleUpdater {
    /// Changes an existing member's role in the budget. Only owners may do this (enforced by
    /// the Firestore rules).
    func update(user userId: UserId, to role: Budget.User.Role, in budget: BudgetInfo) async throws
}

class MockBudgetUserRoleUpdater: BudgetUserRoleUpdater {

    let throwing: Bool

    init(throwing: Bool = false) {
        self.throwing = throwing
    }

    func update(user userId: UserId, to role: Budget.User.Role, in budget: BudgetInfo) async throws {
        try await Task.sleep(for: .seconds(0.5))
        if throwing { throw TextError("MockBudgetUserRoleUpdater.throwing") }
    }
}

extension MockBudgetUserRoleUpdater {

    private static let envKey_TestThrowing: String = "MockBudgetUserRoleUpdater.envKey_TestThrowing"

    public static func test(throwing: Bool, in environment: inout [String:String]) {
        environment[envKey_TestThrowing] = String(throwing)
    }

    static func getTestInstance() -> MockBudgetUserRoleUpdater? {
        guard let throwingStr = ProcessInfo.processInfo.environment[envKey_TestThrowing] else { return nil }
        guard let throwing = Bool(throwingStr) else { return nil }
        return .init(throwing: throwing)
    }
}
