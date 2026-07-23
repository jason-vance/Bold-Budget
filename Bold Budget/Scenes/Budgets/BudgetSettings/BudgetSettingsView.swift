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

    @State private var subscriptionLevel: SubscriptionLevel = .none
    private let subscriptionLevelProvider: SubscriptionLevelProvider

    private let userDataFetcher: UserDataFetcher
    private let budgetUserFetcher: BudgetUserFetcher
    private let budgetFetcher: BudgetFetcher
    private let currentUserIdProvider: CurrentUserIdProvider

    init(budget: StateObject<Budget>) {
        self.init(
            budget: budget,
            userDataFetcher: iocContainer~>UserDataFetcher.self,
            budgetUserFetcher: iocContainer~>BudgetUserFetcher.self,
            subscriptionLevelProvider: iocContainer~>SubscriptionLevelProvider.self,
            budgetFetcher: iocContainer~>BudgetFetcher.self,
            currentUserIdProvider: iocContainer~>CurrentUserIdProvider.self
        )
    }

    init(
        budget: StateObject<Budget>,
        userDataFetcher: UserDataFetcher,
        budgetUserFetcher: BudgetUserFetcher,
        subscriptionLevelProvider: SubscriptionLevelProvider,
        budgetFetcher: BudgetFetcher,
        currentUserIdProvider: CurrentUserIdProvider
    ) {
        self._budget = budget
        self.userDataFetcher = userDataFetcher
        self.budgetUserFetcher = budgetUserFetcher
        self.subscriptionLevelProvider = subscriptionLevelProvider
        self.budgetFetcher = budgetFetcher
        self.currentUserIdProvider = currentUserIdProvider
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
        if otherBudgets.isEmpty {
            ProfileLabel(showsSwitcher: false)
        } else {
            Menu {
                Section("Switch Budget") {
                    ForEach(otherBudgets) { info in
                        Button(info.name.value) { budgetNavigator.open(info) }
                    }
                }
            } label: {
                ProfileLabel(showsSwitcher: true)
            }
            .accessibilityIdentifier("BudgetSettingsView.SwitchBudgetMenu")
        }
    }

    @ViewBuilder private func ProfileLabel(showsSwitcher: Bool) -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(systemName: "chart.pie.fill", size: 64, tint: .brandTeal)
            HStack(spacing: 4) {
                Text(budget.info.name.value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appText)
                    .multilineTextAlignment(.center)
                if showsSwitcher {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appMutedText)
                }
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
                Text("Users")
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .kerning(0.5)
                    .foregroundStyle(Color.appMutedText)
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
                            UserRow(user: user)
                        }
                    }
                }
                .card(0)
            }
        }
    }

    @ViewBuilder private func UserRow(user: UserData, showsChevron: Bool = false) -> some View {
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
        }
        .padding(.padding)
        .contentShape(Rectangle())
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
            currentUserIdProvider: MockCurrentUserIdProvider()
        )
    }
    .environmentObject(AdProviderFactory.forScreenshots)
    .environmentObject(BudgetNavigator())
}
