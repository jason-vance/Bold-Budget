//
//  BudgetsListView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/24/24.
//

import SwiftUI
import SwinjectAutoregistration

struct BudgetsListView: View {
    
    @State private var budgets: [BudgetInfo]? = nil
    
    @State private var subscriptionLevel: SubscriptionLevel? = nil
    @State private var showMarketingView: Bool = false
    
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
        List {
            if let budgets = budgets {
                if budgets.isEmpty {
                    NoBudgetsSection()
                } else {
                    BudgetsSection(budgets)
                }
                AdSection()
            } else {
                BlockingSpinnerView()
                    .listRowNoChrome()
            }
        }
        .animation(.snappy, value: budgets)
        .refreshable { fetchBudgets() }
        .overlay(alignment: .bottomTrailing) { AddBudgetButton() }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .toolbar { Toolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Budgets")
        .foregroundStyle(Color.text)
        .background(Color.background)
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
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            UserProfileButton()
        }
    }
    
    @ViewBuilder private func NoBudgetsSection() -> some View {
        Section {
            ContentUnavailableView(
                "No Budgets",
                systemImage: "square.dashed",
                description: Text("You currently don't have any budgets. Any budgets that you create, or are invited to, will show up here.")
            )
            .listRowNoChrome()
        }
    }
    
    @ViewBuilder private func BudgetsSection(_ budgets: [BudgetInfo]) -> some View {
        Section {
            ForEach(budgets) { budget in
                BudgetRow(budget)
            }
        }
    }
    
    @ViewBuilder private func BudgetRow(_ budget: BudgetInfo) -> some View {
        NavigationLink {
            BudgetDetailView(budget: Budget(info: budget))
        } label: {
            Text(budget.name.value)
        }
        .swipeActions(allowsFullSwipe: false) {
            Button {
                budgetToDelete = budget
                showFirstDeleteBudgetDialog = true
            } label: {
                Image(systemName: "trash")
            }
            .tint(Color.background)
        }
        .listRow()
        .accessibilityIdentifier("BudgetsListView.BudgetRow.\(budget.name.value)")
    }
    
    @ViewBuilder private func AdSection() -> some View {
        if let budgets = budgets, subscriptionLevel == SubscriptionLevel.none {
            Section {
                if budgets.isEmpty {
                    SimpleNativeAdView(size: .small)
                        .listRow()
                } else {
                    SimpleNativeAdView(size: .medium)
                        .listRow()
                }
//            } footer: {
//                RemoveAdsButton()
            }
        }
    }
    
    @ViewBuilder private func RemoveAdsButton() -> some View {
        HStack {
            Spacer()
            Button {
                showMarketingView = true
            } label: {
                Text("Remove Ads")
                    .font(.caption.bold())
                    .foregroundStyle(Color.text)
                    .padding(.horizontal, .paddingHorizontalButtonMedium)
                    .padding(.vertical, .paddingVerticalButtonSmall)
                    .background {
                        Capsule()
                            .foregroundStyle(Color.text.opacity(.opacityButtonBackground))
                    }
            }
            .accessibilityIdentifier("BudgetsListView.RemoveAdsButton")
            Spacer()
        }
    }
    
    @ViewBuilder func AddBudgetButton() -> some View {
        if let count = budgets?.count {
//            if count == 0 || subscriptionLevel == .boldBudgetPlus {
                NavigationLink {
                    EditBudgetView()
                } label: {
                    AddBudgetButtonLabel()
                }
                .padding()
                .accessibilityIdentifier("BudgetsListView.AddBudgetButton")
//            } else {
//                Button {
//                    showMarketingView = true
//                } label: {
//                    AddBudgetButtonLabel()
//                }
//                .padding()
//                .accessibilityIdentifier("BudgetsListView.AddBudgetButton")
//                .fullScreenCover(isPresented: $showMarketingView) {
//                    SubscriptionMarketingView()
//                }
//            }
        }
    }
    
    @ViewBuilder private func AddBudgetButtonLabel() -> some View {
        Image(systemName: "plus")
            .foregroundStyle(Color.background)
            .font(.title)
            .padding()
            .background {
                Circle()
                    .foregroundStyle(Color.text)
                    .shadow(color: Color.background, radius: .padding)
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
}
