//
//  FirebaseBudgetInvitationRepository.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation
import FirebaseFirestore

class FirebaseBudgetInvitationRepository {

    static let BUDGET_INVITATIONS = "BudgetInvitations"

    let invitationsCollection = Firestore.firestore().collection(BUDGET_INVITATIONS)
}

extension FirebaseBudgetInvitationRepository: BudgetInviter {
    func invite(_ invitee: UserData, as role: Budget.User.Role, to budget: BudgetInfo, from inviter: UserData) async throws {
        let invitation = BudgetInvitation(
            id: BudgetInvitation.id(budgetId: budget.id, inviteeUserId: invitee.id),
            budgetId: budget.id,
            budgetName: budget.name,
            inviterUserId: inviter.id,
            inviterUsername: inviter.username,
            inviteeUserId: invitee.id,
            role: role,
            createdAt: .now
        )

        let doc = FirebaseBudgetInvitationDoc.from(invitation)
        try await invitationsCollection.document(invitation.id).setData(from: doc)
    }
}

extension FirebaseBudgetInvitationRepository: BudgetInvitationFetcher {
    func fetchInvitations(for userId: UserId) async throws -> [BudgetInvitation] {
        try await invitationsCollection
            .whereField(FirebaseBudgetInvitationDoc.CodingKeys.inviteeUserId.rawValue, isEqualTo: userId.value)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: FirebaseBudgetInvitationDoc.self).toBudgetInvitation() }
    }
}

extension FirebaseBudgetInvitationRepository: BudgetInvitationResponder {
    func accept(_ invitation: BudgetInvitation) async throws {
        let db = Firestore.firestore()
        let batch = db.batch()

        // 1. Add the invitee to the budget's membership index.
        let budgetRef = db
            .collection(FirebaseBudgetRepository.BUDGETS)
            .document(invitation.budgetId)
        batch.updateData(
            [FirebaseBudgetDoc.CodingKeys.users.rawValue: FieldValue.arrayUnion([invitation.inviteeUserId.value])],
            forDocument: budgetRef
        )

        // 2. Create the invitee's membership doc with the role they were invited as.
        let memberRef = budgetRef
            .collection(FirebaseBudgetUserRepository.USERS)
            .document(invitation.inviteeUserId.value)
        let memberDoc = FirebaseBudgetUserDoc.from(user: .init(id: invitation.inviteeUserId, role: invitation.role))
        try batch.setData(from: memberDoc, forDocument: memberRef)

        // 3. Consume the invitation.
        batch.deleteDocument(invitationsCollection.document(invitation.id))

        try await batch.commit()
    }

    func decline(_ invitation: BudgetInvitation) async throws {
        try await invitationsCollection.document(invitation.id).delete()
    }
}
