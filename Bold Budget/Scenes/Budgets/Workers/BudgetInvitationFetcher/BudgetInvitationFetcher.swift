//
//  BudgetInvitationFetcher.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation

protocol BudgetInvitationFetcher {
    func fetchInvitations(for userId: UserId) async throws -> [BudgetInvitation]
}

class MockBudgetInvitationFetcher: BudgetInvitationFetcher {

    let invitations: [BudgetInvitation]

    init(invitations: [BudgetInvitation] = [.sample]) {
        self.invitations = invitations
    }

    func fetchInvitations(for userId: UserId) async throws -> [BudgetInvitation] {
        return invitations
    }
}

extension MockBudgetInvitationFetcher {

    private static let envKey_TestUsingSample: String = "MockBudgetInvitationFetcher.envKey_TestUsingSample"

    public static func test(usingSample: Bool, in environment: inout [String:String]) {
        environment[envKey_TestUsingSample] = String(usingSample)
    }

    static func getTestInstance() -> MockBudgetInvitationFetcher? {
        guard let useSampleStr = ProcessInfo.processInfo.environment[envKey_TestUsingSample] else { return nil }
        guard let useSample = Bool(useSampleStr) else { return nil }
        return .init(invitations: useSample ? [.sample] : [])
    }
}
