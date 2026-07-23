//
//  BudgetsListView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/24/24.
//

import SwiftUI
import SwinjectAutoregistration

/// The app's home screen in the redesign palette: a self-contained header (centered title + profile
/// button), a scrolling card of budget rows, an optional ad card, and a floating add button. Self-
/// contained (own header + scroll) so it carries the redesign look without the shared List chrome,
/// mirroring `TransactionCategoryPickerView`. Deleting a budget (previously a List swipe action) now
/// lives in a per-row context menu, keeping the two-step confirmation flow.
struct BudgetsListView: View {

    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    @State private var budgets: [BudgetInfo]? = nil

    @State private var subscriptionLevel: SubscriptionLevel? = nil

    @State private var budgetToDelete: BudgetInfo? = nil
    @State private var showFirstDeleteBudgetDialog: Bool = false
    @State private var showSecondDeleteBudgetDialog: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private let budgetFetcher: BudgetFetcher
    private let budgetDeleter: BudgetDeleter
    private let currentUserIdProvider: CurrentUserIdProvider
    private let subscriptionManager: SubscriptionLevelProvider

    init() {
        self.init(
            budgetFetcher: iocContainer~>BudgetFetcher.self,
            budgetDeleter: iocContainer~>BudgetDeleter.self,
            currentUserIdProvider: iocContainer~>CurrentUserIdProvider.self,
            subscriptionManager: iocContainer~>SubscriptionLevelProvider.self
        )
    }

    init(
        budgetFetcher: BudgetFetcher,
        budgetDeleter: BudgetDeleter,
        currentUserIdProvider: CurrentUserIdProvider,
        subscriptionManager: SubscriptionLevelProvider
    ) {
        self.budgetFetcher = budgetFetcher
        self.budgetDeleter = budgetDeleter
        self.currentUserIdProvider = currentUserIdProvider
        self.subscriptionManager = subscriptionManager
    }

    private func fetchBudgets() {
        Task {
            do {
                guard let userId = currentUserIdProvider.currentUserId else {
                    throw TextError("User is apparently not logged in")
                }
                budgets = try await budgetFetcher.fetchBudgets(for: userId)
            } catch {
                let message = "Failed to fetch budgets. \(error.localizedDescription)"
                show(alert: message)
                print(message)
            }
        }
    }

    private func delete(budget: BudgetInfo?) {
        guard let budget else { return }

        Task {
            do {
                try await budgetDeleter.delete(budget: budget)
                budgets = budgets?.filter { $0 != budget }
            } catch {
                print("Failed to delete budget. \(error.localizedDescription)")
            }
        }
    }

    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }

    var body: some View {
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(spacing: .padding) {
                    if let budgets = budgets {
                        if budgets.isEmpty {
                            EmptyState()
                        } else {
                            BudgetsCard(budgets)
                        }
                        AdCard()
                    } else {
                        BlockingSpinnerView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, .padding * 2)
                    }
                }
                .animation(.snappy, value: budgets)
                .padding()
            }
            .scrollIndicators(.hidden)
            .refreshable { fetchBudgets() }
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationDestination(for: BudgetInfo.self) { info in
            BudgetDetailView(budget: Budget(info: info))
                .id(info.id)
        }
        .overlay(alignment: .bottomTrailing) { AddBudgetButton() }
        .toolbar(.hidden, for: .navigationBar)
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .alert(alertMessage, isPresented: $showAlert) {}
        .onAppear { fetchBudgets() }
        .onReceive(subscriptionManager.subscriptionLevelPublisher) { subscriptionLevel = $0 }
        .confirmationDialog(
            "\(budgetToDelete?.name.value ?? "")\nAre you sure you want to delete this budget? It will no longer be accessible by you or anyone else. All of its transaction data will also be deleted. It will not be recoverable.",
            isPresented: $showFirstDeleteBudgetDialog,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                showSecondDeleteBudgetDialog = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog(
            "Are you REALLY sure you want to delete this budget?",
            isPresented: $showSecondDeleteBudgetDialog,
            titleVisibility: .visible
        ) {
            Button("Delete It!", role: .destructive) {
                delete(budget: budgetToDelete)
            }
            Button("Nevermind", role: .cancel) { }
        }
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text("Budgets")
                .font(.headline)
                .foregroundStyle(Color.appText)
                .padding(.horizontal, .barHeight)
            HStack {
                Spacer(minLength: 0)
                UserProfileButton()
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Budgets

    @ViewBuilder private func BudgetsCard(_ budgets: [BudgetInfo]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(budgets.enumerated()), id: \.element.id) { index, budget in
                if index > 0 { RowDivider() }
                BudgetRow(budget)
            }
        }
        .card(0)
    }

    @ViewBuilder private func BudgetRow(_ budget: BudgetInfo) -> some View {
        NavigationLink(value: budget) {
            HStack(spacing: .padding) {
                IconCircle(systemName: "chart.pie.fill", size: 40, tint: .brandTeal)
                Text(budget.name.value)
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
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                budgetToDelete = budget
                showFirstDeleteBudgetDialog = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityIdentifier("BudgetsListView.BudgetRow.\(budget.name.value)")
    }

    @ViewBuilder private func RowDivider(opacity: Double = 0.15) -> some View {
        Rectangle()
            .fill(Color.appMutedText.opacity(opacity))
            .frame(height: 1)
            .padding(.leading, .padding)
    }

    // MARK: - Empty state

    @ViewBuilder private func EmptyState() -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(systemName: "square.dashed", size: 56, tint: .brandTeal)
            Text("No Budgets")
                .font(.title3.weight(.bold))
            Text("You currently don't have any budgets. Any budgets that you create, or are invited to, will show up here.")
                .font(.subheadline)
                .foregroundStyle(Color.appMutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .padding * 2)
    }

    // MARK: - Ad

    @ViewBuilder private func AdCard() -> some View {
        if let budgets = budgets, subscriptionLevel == SubscriptionLevel.none {
            NativeAdListRow(ad: $ad, size: budgets.isEmpty ? .small : .medium)
                .frame(maxWidth: .infinity)
                .card()
        }
    }

    // MARK: - Add

    @ViewBuilder private func AddBudgetButton() -> some View {
        if budgets != nil {
            NavigationLink {
                EditBudgetView()
            } label: {
                Image(systemName: "plus")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(Color.appBackground)
                    .padding()
                    .background {
                        Circle()
                            .foregroundStyle(Color.brandTeal)
                            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    }
            }
            .padding()
            .accessibilityIdentifier("BudgetsListView.AddBudgetButton")
        }
    }
}

#Preview {
    NavigationStack {
        BudgetsListView(
            budgetFetcher: MockBudgetFetcher(),
            budgetDeleter: MockBudgetDeleter(),
            currentUserIdProvider: MockCurrentUserIdProvider(),
            subscriptionManager: MockSubscriptionLevelProvider(level: .none)
        )
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}

#Preview("No budgets") {
    NavigationStack {
        BudgetsListView(
            budgetFetcher: MockBudgetFetcher(budgets: []),
            budgetDeleter: MockBudgetDeleter(),
            currentUserIdProvider: MockCurrentUserIdProvider(),
            subscriptionManager: MockSubscriptionLevelProvider(level: .none)
        )
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}
