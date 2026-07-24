//
//  BudgetInvitation.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation

struct BudgetInvitation: Identifiable {

    let id: String
    let budgetId: String
    let budgetName: BudgetInfo.Name
    let inviterUserId: UserId
    let inviterUsername: Username?
    let inviteeUserId: UserId
    let createdAt: Date

    /// Deterministic id so re-inviting the same person to the same budget overwrites
    /// the pending invite rather than creating a duplicate.
    static func id(budgetId: String, inviteeUserId: UserId) -> String {
        "\(budgetId)_\(inviteeUserId.value)"
    }

    static let sample: BudgetInvitation = .init(
        id: id(budgetId: BudgetInfo.sample.id, inviteeUserId: .sample),
        budgetId: BudgetInfo.sample.id,
        budgetName: .sample,
        inviterUserId: .sample,
        inviterUsername: Username("ifrit"),
        inviteeUserId: .sample,
        createdAt: .now
    )
}

extension BudgetInvitation: Equatable {}

extension BudgetInvitation: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
