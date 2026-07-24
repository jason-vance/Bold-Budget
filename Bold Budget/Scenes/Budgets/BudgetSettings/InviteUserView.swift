//
//  InviteUserView.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/23/26.
//

import SwiftUI
import Combine
import SwinjectAutoregistration

/// Invites another user to a budget by username: type a username, look them up, and send an
/// invitation they can later accept. Presented as a sheet from `BudgetSettingsView`.
struct InviteUserView: View {

    enum Status: Equatable {
        case idle
        case searching
        case notFound
        case found(UserData)
        case isSelf
        case alreadyMember
    }

    @Environment(\.dismiss) private var dismiss: DismissAction

    let budget: BudgetInfo
    let existingMemberIds: [UserId]

    @State private var usernameStr: String = ""
    @State private var status: Status = .idle
    @State private var inviter: UserData?

    private let userFinder: UserFinder
    private let budgetInviter: BudgetInviter
    private let currentUserDataProvider: CurrentUserDataProvider
    private let popupNotificationCenter: PopupNotificationCenter

    init(budget: BudgetInfo, existingMemberIds: [UserId]) {
        self.init(
            budget: budget,
            existingMemberIds: existingMemberIds,
            userFinder: iocContainer~>UserFinder.self,
            budgetInviter: iocContainer~>BudgetInviter.self,
            currentUserDataProvider: iocContainer~>CurrentUserDataProvider.self,
            popupNotificationCenter: iocContainer~>PopupNotificationCenter.self
        )
    }

    init(
        budget: BudgetInfo,
        existingMemberIds: [UserId],
        userFinder: UserFinder,
        budgetInviter: BudgetInviter,
        currentUserDataProvider: CurrentUserDataProvider,
        popupNotificationCenter: PopupNotificationCenter
    ) {
        self.budget = budget
        self.existingMemberIds = existingMemberIds
        self.userFinder = userFinder
        self.budgetInviter = budgetInviter
        self.currentUserDataProvider = currentUserDataProvider
        self.popupNotificationCenter = popupNotificationCenter
    }

    private var enteredUsername: Username? { Username(usernameStr) }

    private func search() {
        guard let username = enteredUsername else {
            status = .idle
            return
        }

        status = .searching
        Task {
            do {
                guard let user = try await userFinder.findUser(byUsername: username) else {
                    status = .notFound
                    return
                }

                if user.id == inviter?.id {
                    status = .isSelf
                } else if existingMemberIds.contains(user.id) {
                    status = .alreadyMember
                } else {
                    status = .found(user)
                }
            } catch {
                status = .notFound
            }
        }
    }

    private func sendInvite() async -> TaskStatus {
        guard case .found(let invitee) = status else {
            return .failed(String(localized: "Find a user to invite first."))
        }
        guard let inviter else {
            return .failed(String(localized: "Couldn't determine who's inviting."))
        }

        do {
            try await budgetInviter.invite(invitee, to: budget, from: inviter)
            await MainActor.run {
                popupNotificationCenter.genericNotification(
                    String(localized: "Invitation sent"),
                    subtitle: invitee.username?.value,
                    sfSymbol: "paperplane.fill"
                )
                dismiss()
            }
            return .success
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(spacing: .padding) {
                    SearchField()
                    ResultCard()
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .onReceive(currentUserDataProvider.currentUserDataPublisher) { inviter = $0 }
        .animation(.snappy, value: status)
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text("Add User")
                .font(.headline)
                .foregroundStyle(Color.appText)
                .lineLimit(1)
                .padding(.horizontal, .barHeight)
            HStack {
                Spacer(minLength: 0)
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                }
                .accessibilityIdentifier("InviteUserView.CloseButton")
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Search field

    @ViewBuilder private func SearchField() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Username")
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .kerning(0.5)
                .foregroundStyle(Color.appMutedText)
            HStack(spacing: .paddingSmall) {
                TextField(
                    "Username",
                    text: $usernameStr,
                    prompt: Text("Username").foregroundStyle(Color.appMutedText)
                )
                .font(.title3)
                .foregroundStyle(Color.appText)
                .tint(Color.brandTeal)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { search() }
                .accessibilityIdentifier("InviteUserView.UsernameField")
                Button { search() } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(enteredUsername == nil ? Color.appMutedText : Color.brandTeal)
                }
                .disabled(enteredUsername == nil)
                .accessibilityIdentifier("InviteUserView.SearchButton")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    // MARK: - Result

    @ViewBuilder private func ResultCard() -> some View {
        switch status {
        case .idle:
            EmptyView()
        case .searching:
            HintRow(icon: "questionmark.circle.fill", text: String(localized: "Searching..."), color: .appMutedText)
        case .notFound:
            HintRow(icon: "person.slash.fill", text: String(localized: "No user found with that username."), color: .appMutedText)
        case .isSelf:
            HintRow(icon: "person.fill", text: String(localized: "That's you — you're already in this budget."), color: .appMutedText)
        case .alreadyMember:
            HintRow(icon: "checkmark.circle.fill", text: String(localized: "This user is already in the budget."), color: .brandTeal)
        case .found(let user):
            FoundUserCard(user: user)
        }
    }

    @ViewBuilder private func HintRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: .paddingSmall) {
            Image(systemName: icon)
            Text(text)
            Spacer(minLength: 0)
        }
        .font(.callout)
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    @ViewBuilder private func FoundUserCard(user: UserData) -> some View {
        VStack(spacing: .padding) {
            HStack(spacing: .padding) {
                ProfileImageView(
                    user.profileImageUrl,
                    size: 44,
                    padding: .borderWidthThin
                )
                if let username = user.username {
                    Text(username.value)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.appText)
                }
                Spacer(minLength: 0)
            }
            TaskAwareButton(
                buttonColor: .brandTeal,
                contentColor: .white,
                action: sendInvite
            ) {
                HStack(spacing: .paddingSmall) {
                    Image(systemName: "paperplane.fill")
                    Text("Send Invitation")
                }
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("InviteUserView.SendInvitationButton")
        }
        .card()
    }
}

#Preview {
    InviteUserView(
        budget: .sample,
        existingMemberIds: [],
        userFinder: MockUserFinder(),
        budgetInviter: MockBudgetInviter(),
        currentUserDataProvider: MockCurrentUserDataProvider(),
        popupNotificationCenter: PopupNotificationCenter()
    )
}
