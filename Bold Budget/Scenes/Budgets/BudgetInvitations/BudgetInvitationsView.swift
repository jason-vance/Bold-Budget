//
//  BudgetInvitationsView.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/23/26.
//

import SwiftUI
import SwinjectAutoregistration

/// Lists the current user's pending budget invitations and lets them accept (join the budget)
/// or decline. Reached from `UserProfileView`.
struct BudgetInvitationsView: View {

    @Environment(\.dismiss) private var dismiss: DismissAction

    @State private var invitations: [BudgetInvitation] = []
    @State private var isLoading: Bool = true
    @State private var workingIds: Set<String> = []

    private let currentUserIdProvider: CurrentUserIdProvider
    private let invitationFetcher: BudgetInvitationFetcher
    private let invitationResponder: BudgetInvitationResponder
    private let popupNotificationCenter: PopupNotificationCenter

    init() {
        self.init(
            currentUserIdProvider: iocContainer~>CurrentUserIdProvider.self,
            invitationFetcher: iocContainer~>BudgetInvitationFetcher.self,
            invitationResponder: iocContainer~>BudgetInvitationResponder.self,
            popupNotificationCenter: iocContainer~>PopupNotificationCenter.self
        )
    }

    init(
        currentUserIdProvider: CurrentUserIdProvider,
        invitationFetcher: BudgetInvitationFetcher,
        invitationResponder: BudgetInvitationResponder,
        popupNotificationCenter: PopupNotificationCenter
    ) {
        self.currentUserIdProvider = currentUserIdProvider
        self.invitationFetcher = invitationFetcher
        self.invitationResponder = invitationResponder
        self.popupNotificationCenter = popupNotificationCenter
    }

    private func fetchInvitations() {
        Task {
            defer { isLoading = false }
            guard let userId = currentUserIdProvider.currentUserId else { return }
            do {
                invitations = try await invitationFetcher.fetchInvitations(for: userId)
                    .sorted { $0.createdAt > $1.createdAt }
            } catch {
                print("Failed to fetch invitations. \(error.localizedDescription)")
            }
        }
    }

    private func accept(_ invitation: BudgetInvitation) {
        workingIds.insert(invitation.id)
        Task {
            defer { workingIds.remove(invitation.id) }
            do {
                try await invitationResponder.accept(invitation)
                invitations.removeAll { $0.id == invitation.id }
                popupNotificationCenter.genericNotification(
                    String(localized: "Joined budget"),
                    subtitle: invitation.budgetName.value,
                    sfSymbol: "checkmark.circle.fill"
                )
            } catch {
                popupNotificationCenter.errorNotification(
                    String(localized: "Couldn't join budget"),
                    error: error
                )
            }
        }
    }

    private func decline(_ invitation: BudgetInvitation) {
        workingIds.insert(invitation.id)
        Task {
            defer { workingIds.remove(invitation.id) }
            do {
                try await invitationResponder.decline(invitation)
                invitations.removeAll { $0.id == invitation.id }
            } catch {
                popupNotificationCenter.errorNotification(
                    String(localized: "Couldn't decline invitation"),
                    error: error
                )
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(spacing: .padding) {
                    if isLoading {
                        ProgressView()
                            .tint(Color.brandTeal)
                            .padding(.top, .padding)
                    } else if invitations.isEmpty {
                        EmptyState()
                    } else {
                        ForEach(invitations) { invitation in
                            InvitationCard(invitation)
                        }
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .onAppear { fetchInvitations() }
        .animation(.snappy, value: invitations)
        .animation(.snappy, value: isLoading)
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text("Invitations")
                .font(.headline)
                .foregroundStyle(Color.appText)
                .lineLimit(1)
                .padding(.horizontal, .barHeight)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                }
                .accessibilityIdentifier("BudgetInvitationsView.BackButton")
                Spacer(minLength: 0)
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Empty state

    @ViewBuilder private func EmptyState() -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(systemName: "envelope", size: 64, tint: .brandTeal)
            Text("No pending invitations")
                .font(.headline)
                .foregroundStyle(Color.appText)
            Text("When someone invites you to a budget, it'll show up here.")
                .font(.callout)
                .foregroundStyle(Color.appMutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, .padding)
    }

    // MARK: - Invitation card

    @ViewBuilder private func InvitationCard(_ invitation: BudgetInvitation) -> some View {
        let isWorking = workingIds.contains(invitation.id)
        VStack(spacing: .padding) {
            HStack(spacing: .padding) {
                IconCircle(systemName: "chart.pie.fill", size: 44, tint: .brandTeal)
                VStack(alignment: .leading, spacing: 2) {
                    Text(invitation.budgetName.value)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.appText)
                    if let inviter = invitation.inviterUsername {
                        Text("Invited by \(inviter.value)")
                            .font(.caption)
                            .foregroundStyle(Color.appMutedText)
                    }
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: .padding) {
                Button { decline(invitation) } label: {
                    Text("Decline")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.appText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, .paddingVerticalButtonMedium)
                        .background {
                            RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                                .foregroundStyle(Color.appSurface)
                        }
                }
                .disabled(isWorking)
                .accessibilityIdentifier("BudgetInvitationsView.DeclineButton")
                Button { accept(invitation) } label: {
                    Text("Accept")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, .paddingVerticalButtonMedium)
                        .background {
                            RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                                .foregroundStyle(Color.brandTeal)
                        }
                }
                .disabled(isWorking)
                .accessibilityIdentifier("BudgetInvitationsView.AcceptButton")
            }
            .overlay {
                if isWorking {
                    ProgressView().tint(Color.brandTeal)
                }
            }
        }
        .card()
    }
}

#Preview {
    NavigationStack {
        BudgetInvitationsView(
            currentUserIdProvider: MockCurrentUserIdProvider(),
            invitationFetcher: MockBudgetInvitationFetcher(invitations: [
                .sample,
                .init(
                    id: UUID().uuidString,
                    budgetId: UUID().uuidString,
                    budgetName: .init("Side Business")!,
                    inviterUserId: .sample,
                    inviterUsername: Username("shiva"),
                    inviteeUserId: .sample,
                    createdAt: .now
                ),
            ]),
            invitationResponder: MockBudgetInvitationResponder(),
            popupNotificationCenter: PopupNotificationCenter()
        )
    }
}
