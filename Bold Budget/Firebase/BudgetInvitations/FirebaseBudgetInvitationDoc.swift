//
//  FirebaseBudgetInvitationDoc.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation
import FirebaseFirestore

struct FirebaseBudgetInvitationDoc: Codable {

    @DocumentID var id: String?
    var budgetId: String?
    var budgetName: String?
    var inviterUserId: String?
    var inviterUsername: String?
    var inviteeUserId: String?
    var role: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case budgetId
        case budgetName
        case inviterUserId
        case inviterUsername
        case inviteeUserId
        case role
        case createdAt
    }

    static func from(_ invitation: BudgetInvitation) -> FirebaseBudgetInvitationDoc {
        .init(
            id: invitation.id,
            budgetId: invitation.budgetId,
            budgetName: invitation.budgetName.value,
            inviterUserId: invitation.inviterUserId.value,
            inviterUsername: invitation.inviterUsername?.value,
            inviteeUserId: invitation.inviteeUserId.value,
            role: invitation.role.rawValue,
            createdAt: invitation.createdAt
        )
    }

    func toBudgetInvitation() -> BudgetInvitation? {
        guard let id = id else { return nil }
        guard let budgetId = budgetId else { return nil }
        guard let budgetName = BudgetInfo.Name(budgetName) else { return nil }
        guard let inviterUserId = UserId(inviterUserId) else { return nil }
        guard let inviteeUserId = UserId(inviteeUserId) else { return nil }
        guard let createdAt = createdAt else { return nil }
        // Legacy invites predate roles and were all equal co-owners.
        let role = Budget.User.Role(rawValue: role ?? "") ?? .owner

        return .init(
            id: id,
            budgetId: budgetId,
            budgetName: budgetName,
            inviterUserId: inviterUserId,
            inviterUsername: Username(inviterUsername),
            inviteeUserId: inviteeUserId,
            role: role,
            createdAt: createdAt
        )
    }
}
