//
//  BudgetInviter.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation

protocol BudgetInviter {
    func invite(_ invitee: UserData, to budget: BudgetInfo, from inviter: UserData) async throws
}

class MockBudgetInviter: BudgetInviter {

    let throwing: Bool

    init(throwing: Bool = false) {
        self.throwing = throwing
    }

    func invite(_ invitee: UserData, to budget: BudgetInfo, from inviter: UserData) async throws {
        try await Task.sleep(for: .seconds(0.5))
        if throwing { throw TextError("MockBudgetInviter.throwing") }
    }
}

extension MockBudgetInviter {

    private static let envKey_TestThrowing: String = "MockBudgetInviter.envKey_TestThrowing"

    public static func test(throwing: Bool, in environment: inout [String:String]) {
        environment[envKey_TestThrowing] = String(throwing)
    }

    static func getTestInstance() -> MockBudgetInviter? {
        guard let throwingStr = ProcessInfo.processInfo.environment[envKey_TestThrowing] else { return nil }
        guard let throwing = Bool(throwingStr) else { return nil }
        return .init(throwing: throwing)
    }
}
