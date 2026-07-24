//
//  BudgetSettingsView.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/3/25.
//

import SwiftUI
import SwinjectAutoregistration

/// The budget's settings, redesign palette: a title header with a back button, a budget profile
/// badge, an optional ad card, navigation rows (rename, categories), and a users card. Self-contained
/// (own header + scroll) so it carries the redesign look without the shared List chrome, mirroring
/// `RecurringExpensesView`.
struct BudgetSettingsView: View {

    @Environment(\.dismiss) private var dismiss: DismissAction

    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @EnvironmentObject private var budgetNavigator: BudgetNavigator
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    @StateObject var budget: Budget

    @State private var users: [UserData] = []
    @State private var budgetUsers: [UserId:Budget.User] = [:]
    @State private var allBudgets: [BudgetInfo] = []
    @State private var showAddBudget: Bool = false
    @State private var showInviteUser: Bool = false

    @State private var subscriptionLevel: SubscriptionLevel = .none
    private let subscriptionLevelProvider: SubscriptionLevelProvider

    private let userDataFetcher: UserDataFetcher
    private let budgetUserFetcher: BudgetUserFetcher
    private let budgetFetcher: BudgetFetcher
    private let currentUserIdProvider: CurrentUserIdProvider
    private let budgetUserRemover: BudgetUserRemover
    private let popupNotificationCenter: PopupNotificationCenter

    @State private var userPendingRemoval: UserData?
    @State private var showLeaveConfirmation: Bool = false

    init(budget: StateObject<Budget>) {
        self.init(
            budget: budget,
            userDataFetcher: iocContainer~>UserDataFetcher.self,
            budgetUserFetcher: iocContainer~>BudgetUserFetcher.self,
            subscriptionLevelProvider: iocContainer~>SubscriptionLevelProvider.self,
            budgetFetcher: iocContainer~>BudgetFetcher.self,
            currentUserIdProvider: iocContainer~>CurrentUserIdProvider.self,
            budgetUserRemover: iocContainer~>BudgetUserRemover.self,
            popupNotificationCenter: iocContainer~>PopupNotificationCenter.self
        )
    }

    init(
        budget: StateObject<Budget>,
        userDataFetcher: UserDataFetcher,
        budgetUserFetcher: BudgetUserFetcher,
        subscriptionLevelProvider: SubscriptionLevelProvider,
        budgetFetcher: BudgetFetcher,
        currentUserIdProvider: CurrentUserIdProvider,
        budgetUserRemover: BudgetUserRemover,
        popupNotificationCenter: PopupNotificationCenter
    ) {
        self._budget = budget
        self.userDataFetcher = userDataFetcher
        self.budgetUserFetcher = budgetUserFetcher
        self.subscriptionLevelProvider = subscriptionLevelProvider
        self.budgetFetcher = budgetFetcher
        self.currentUserIdProvider = currentUserIdProvider
        self.budgetUserRemover = budgetUserRemover
        self.popupNotificationCenter = popupNotificationCenter
    }

    /// Removes a user from the budget and syncs local state. When the current user leaves, the
    /// settings screen pops back to the root budget list (they no longer have access).
    private func remove(_ user: UserData) {
        let isLeaving = user.id == currentUserIdProvider.currentUserId
        Task {
            do {
                try await budgetUserRemover.remove(user: user.id, from: budget.info)
                users.removeAll { $0.id == user.id }
                budgetUsers[user.id] = nil
                budget.info = .init(
                    id: budget.info.id,
                    name: budget.info.name,
                    users: budget.info.users.filter { $0 != user.id }
                )
                if isLeaving {
                    popupNotificationCenter.genericNotification(
                        String(localized: "Left budget"),
                        subtitle: budget.info.name.value,
                        sfSymbol: "figure.walk.departure"
                    )
                    budgetNavigator.path = []
                    dismiss()
                }
            } catch {
                popupNotificationCenter.errorNotification(
                    String(localized: "Couldn't remove user"),
                    error: error
                )
            }
        }
    }

    /// Budgets other than the one being viewed, for the switcher menu.
    private var otherBudgets: [BudgetInfo] {
        allBudgets
            .filter { $0.id != budget.id }
            .sorted { $0.name.value < $1.name.value }
    }

    private func fetchBudgets() {
        Task {
            guard let userId = currentUserIdProvider.currentUserId else { return }
            do {
                allBudgets = try await budgetFetcher.fetchBudgets(for: userId)
            } catch {
                print("Failed to fetch budgets. \(error.localizedDescription)")
            }
        }
    }
    
    private func removeUserPrompt(for user: UserData) -> String {
        let name = user.username?.value ?? String(localized: "this user")
        return String(localized: "Remove \(name) from \(budget.info.name.value)?")
    }

    private func fetchUsers() {
        Task {
            do {
                users = try await withThrowingTaskGroup(of: UserData.self) { group in
                    for userId in budget.info.users {
                        group.addTask {
                            return try await userDataFetcher.fetchUserData(withId: userId)
                        }
                    }
                    
                    var allUsers = [UserData]()
                    
                    for try await user in group {
                        allUsers.append(user)
                    }
                                        
                    return allUsers.sorted { $0.username?.value ?? "" > $1.username?.value ?? "" }
                }
            } catch {
                print("Failed to fetch users. \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchUserRoles() {
        Task {
            do {
                let users = try await budgetUserFetcher.fetchUsers(in: budget.info)
                budgetUsers = .init(uniqueKeysWithValues: users.map { ($0.id, $0) })
            } catch {
                print("Failed to fetch users' roles. \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(spacing: .padding) {
                    Profile()
                    AdCard()
                    ActionsCard()
                    UsersCard()
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .fullScreenCover(isPresented: $showAddBudget, onDismiss: { fetchBudgets() }) {
            NavigationStack { EditBudgetView() }
        }
        .sheet(isPresented: $showInviteUser, onDismiss: { fetchUsers() }) {
            InviteUserView(budget: budget.info, existingMemberIds: budget.info.users)
        }
        .confirmationDialog(
            userPendingRemoval.flatMap { removeUserPrompt(for: $0) } ?? "",
            isPresented: Binding(
                get: { userPendingRemoval != nil },
                set: { if !$0 { userPendingRemoval = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let user = userPendingRemoval {
                Button("Remove", role: .destructive) { remove(user) }
                Button("Cancel", role: .cancel) {}
            }
        }
        .confirmationDialog(
            "Leave \(budget.info.name.value)? You'll lose access to this budget.",
            isPresented: $showLeaveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Leave Budget", role: .destructive) {
                if let me = users.first(where: { $0.id == currentUserIdProvider.currentUserId }) {
                    remove(me)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear { fetchUsers() }
        .onAppear { fetchUserRoles() }
        .onAppear { fetchBudgets() }
        .animation(.snappy, value: users)
        .animation(.snappy, value: budgetUsers)
        .onReceive(subscriptionLevelProvider.subscriptionLevelPublisher) { subscriptionLevel = $0 }
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text(budget.info.name.value)
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
                .accessibilityIdentifier("BudgetSettingsView.BackButton")
                Spacer(minLength: 0)
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Profile

    @ViewBuilder private func Profile() -> some View {
        Menu {
            if !otherBudgets.isEmpty {
                Section("Switch Budget") {
                    ForEach(otherBudgets) { info in
                        Button(info.name.value) { budgetNavigator.open(info) }
                    }
                }
            }
            Button {
                showAddBudget = true
            } label: {
                Label("Add Budget", systemImage: "plus")
            }
        } label: {
            ProfileLabel()
        }
        .accessibilityIdentifier("BudgetSettingsView.SwitchBudgetMenu")
    }

    @ViewBuilder private func ProfileLabel() -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(systemName: "chart.pie.fill", size: 64, tint: .brandTeal)
            HStack(spacing: 4) {
                Text(budget.info.name.value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appText)
                    .multilineTextAlignment(.center)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appMutedText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, .paddingSmall)
    }

    // MARK: - Ad

    @ViewBuilder private func AdCard() -> some View {
        if subscriptionLevel == SubscriptionLevel.none {
            NativeAdListRow(ad: $ad, size: .small)
                .frame(maxWidth: .infinity)
                .card()
        }
    }

    // MARK: - Actions

    @ViewBuilder private func ActionsCard() -> some View {
        VStack(spacing: 0) {
            NavigationLink {
                EditBudgetView()
                    .editing(budget)
            } label: {
                NavRow(systemName: "pencil", title: "Rename Budget")
            }
            .buttonStyle(.plain)
            RowDivider()
            NavigationLink {
                TransactionCategoryPickerView(
                    budget: budget,
                    selectedCategoryId: .init(get: { .none }, set: { _ in })
                )
                .pickerMode(.editor)
            } label: {
                NavRow(systemName: "tag.fill", title: "Transaction Categories")
            }
            .buttonStyle(.plain)
        }
        .card(0)
    }

    @ViewBuilder private func NavRow(systemName: String, title: LocalizedStringKey) -> some View {
        HStack(spacing: .padding) {
            IconCircle(systemName: systemName, size: 40, tint: .brandTeal)
            Text(title)
                .fontWeight(.semibold)
                .foregroundStyle(Color.appText)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appMutedText)
        }
        .padding(.padding)
        .contentShape(Rectangle())
    }

    // MARK: - Users

    @ViewBuilder private func UsersCard() -> some View {
        if !users.isEmpty {
            VStack(alignment: .leading, spacing: .paddingSmall) {
                HStack(spacing: 0) {
                    Text("Users")
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .kerning(0.5)
                        .foregroundStyle(Color.appMutedText)
                    Spacer(minLength: 0)
                    Button { showInviteUser = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Add")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandTeal)
                    }
                    .accessibilityIdentifier("BudgetSettingsView.AddUserButton")
                }
                .padding(.horizontal, .paddingSmall)
                VStack(spacing: 0) {
                    ForEach(Array(users.enumerated()), id: \.element.id) { index, user in
                        if index > 0 { RowDivider() }
                        if user.id == currentUserIdProvider.currentUserId {
                            NavigationLink {
                                UserProfileView(userId: user.id)
                            } label: {
                                UserRow(user: user, showsChevron: true)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("BudgetSettingsView.CurrentUserRow")
                        } else {
                            UserRow(user: user, showsRemoveMenu: true)
                        }
                    }
                }
                .card(0)
                LeaveBudgetButton()
            }
        }
    }

    @ViewBuilder private func UserRow(user: UserData, showsChevron: Bool = false, showsRemoveMenu: Bool = false) -> some View {
        HStack(spacing: .padding) {
            ProfileImageView(
                user.profileImageUrl,
                size: 40,
                padding: .borderWidthThin
            )
            if let username = user.username {
                Text(username.value)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appText)
            }
            Spacer(minLength: 0)
            if let role = budgetUsers[user.id]?.role {
                Text(String(describing: role).capitalized)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appMutedText)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appMutedText)
            }
            if showsRemoveMenu {
                Menu {
                    Button(role: .destructive) {
                        userPendingRemoval = user
                    } label: {
                        Label("Remove from Budget", systemImage: "person.badge.minus")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("BudgetSettingsView.UserOptionsMenu")
            }
        }
        .padding(.padding)
        .contentShape(Rectangle())
    }

    @ViewBuilder private func LeaveBudgetButton() -> some View {
        Button {
            showLeaveConfirmation = true
        } label: {
            HStack(spacing: .paddingSmall) {
                Image(systemName: "figure.walk.departure")
                Text("Leave Budget")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.negative)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .paddingVerticalButtonMedium)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .foregroundStyle(Color.appSurface)
            }
        }
        .padding(.top, .paddingSmall)
        .accessibilityIdentifier("BudgetSettingsView.LeaveBudgetButton")
    }

    @ViewBuilder private func RowDivider(opacity: Double = 0.15) -> some View {
        Rectangle()
            .fill(Color.appMutedText.opacity(opacity))
            .frame(height: 1)
            .padding(.leading, .padding)
    }
}

#Preview {
    NavigationStack {
        BudgetSettingsView(
            budget: .init(wrappedValue: Budget(info: .sample)),
            userDataFetcher: MockUserDataFetcher(),
            budgetUserFetcher: MockBudgetUserFetcher(),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .boldBudgetPlus),
            budgetFetcher: MockBudgetFetcher(budgets: [
                .sample,
                .init(id: UUID().uuidString, name: .init("Personal")!, users: [.sample]),
                .init(id: UUID().uuidString, name: .init("Side Business")!, users: [.sample]),
            ]),
            currentUserIdProvider: MockCurrentUserIdProvider(),
            budgetUserRemover: MockBudgetUserRemover(),
            popupNotificationCenter: PopupNotificationCenter()
        )
    }
    .environmentObject(AdProviderFactory.forScreenshots)
    .environmentObject(BudgetNavigator())
}
