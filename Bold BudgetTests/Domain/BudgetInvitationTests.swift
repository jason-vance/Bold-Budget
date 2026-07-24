//
//  BudgetInvitationTests.swift
//  Bold BudgetTests
//
//  Created by Jason Vance on 7/23/26.
//

import Testing
import Foundation

struct BudgetInvitationTests {

    @Test func idIsDeterministicForBudgetAndInvitee() {
        let budgetId = "budget-123"
        let invitee = UserId("user-abc")!

        let a = BudgetInvitation.id(budgetId: budgetId, inviteeUserId: invitee)
        let b = BudgetInvitation.id(budgetId: budgetId, inviteeUserId: invitee)

        #expect(a == b)
        #expect(a == "budget-123_user-abc")
    }

    @Test func idDiffersByInvitee() {
        let budgetId = "budget-123"
        let one = BudgetInvitation.id(budgetId: budgetId, inviteeUserId: UserId("user-abc")!)
        let two = BudgetInvitation.id(budgetId: budgetId, inviteeUserId: UserId("user-xyz")!)

        #expect(one != two)
    }

    @Test func idDiffersByBudget() {
        let invitee = UserId("user-abc")!
        let one = BudgetInvitation.id(budgetId: "budget-1", inviteeUserId: invitee)
        let two = BudgetInvitation.id(budgetId: "budget-2", inviteeUserId: invitee)

        #expect(one != two)
    }

    @Test func identicalInvitationsAreEqualAndHashAlike() {
        let base = BudgetInvitation.sample
        let copy = BudgetInvitation(
            id: base.id,
            budgetId: base.budgetId,
            budgetName: base.budgetName,
            inviterUserId: base.inviterUserId,
            inviterUsername: base.inviterUsername,
            inviteeUserId: base.inviteeUserId,
            role: base.role,
            createdAt: base.createdAt
        )

        #expect(base == copy)
        #expect(base.hashValue == copy.hashValue)
    }

    @Test func differentIdsAreNotEqual() {
        let base = BudgetInvitation.sample
        let other = BudgetInvitation(
            id: "some-other-id",
            budgetId: base.budgetId,
            budgetName: base.budgetName,
            inviterUserId: base.inviterUserId,
            inviterUsername: base.inviterUsername,
            inviteeUserId: base.inviteeUserId,
            role: base.role,
            createdAt: base.createdAt
        )

        #expect(base != other)
    }
}
