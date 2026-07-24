//
//  BudgetInvitationResponder.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation

protocol BudgetInvitationResponder {
    /// Adds the invitee to the budget and removes the invitation.
    func accept(_ invitation: BudgetInvitation) async throws
    /// Removes the invitation without joining the budget.
    func decline(_ invitation: BudgetInvitation) async throws
}

class MockBudgetInvitationResponder: BudgetInvitationResponder {

    let throwing: Bool

    init(throwing: Bool = false) {
        self.throwing = throwing
    }

    func accept(_ invitation: BudgetInvitation) async throws {
        try await Task.sleep(for: .seconds(0.5))
        if throwing { throw TextError("MockBudgetInvitationResponder.throwing") }
    }

    func decline(_ invitation: BudgetInvitation) async throws {
        try await Task.sleep(for: .seconds(0.5))
        if throwing { throw TextError("MockBudgetInvitationResponder.throwing") }
    }
}

extension MockBudgetInvitationResponder {

    private static let envKey_TestThrowing: String = "MockBudgetInvitationResponder.envKey_TestThrowing"

    public static func test(throwing: Bool, in environment: inout [String:String]) {
        environment[envKey_TestThrowing] = String(throwing)
    }

    static func getTestInstance() -> MockBudgetInvitationResponder? {
        guard let throwingStr = ProcessInfo.processInfo.environment[envKey_TestThrowing] else { return nil }
        guard let throwing = Bool(throwingStr) else { return nil }
        return .init(throwing: throwing)
    }
}
