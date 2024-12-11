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
    
    @State private var showMarketingView: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    private let budgetFetcher: BudgetFetcher
    private let currentUserIdProvider: CurrentUserIdProvider
    private let subscriptionManager: SubscriptionLevelProvider
    
    init() {
        self.init(
            budgetFetcher: iocContainer~>BudgetFetcher.self,
            currentUserIdProvider: iocContainer~>CurrentUserIdProvider.self,
            subscriptionManager: iocContainer~>SubscriptionLevelProvider.self
        )
    }
    
    init(
        budgetFetcher: BudgetFetcher,
        currentUserIdProvider: CurrentUserIdProvider,
        subscriptionManager: SubscriptionLevelProvider
    ) {
        self.budgetFetcher = budgetFetcher
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
    
    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }
    
    var body: some View {
        List {
            if let budgets = budgets {
                if budgets.isEmpty {
                    ContentUnavailableView(
                        "No Budgets",
                        systemImage: "square.dashed",
                        description: Text("You currently don't have any budgets. Any budgets that you create, or are invited to, will show up here.")
                    )
                    .listRowNoChrome()
                } else {
                    BudgetsSection(budgets)
                }
            } else {
                BlockingSpinnerView()
                    .listRowNoChrome()
            }
        }
        .refreshable { fetchBudgets() }
        .safeAreaInset(edge: .bottom, alignment: .trailing) { AddBudgetButton() }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .toolbar { Toolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Budgets")
        .foregroundStyle(Color.text)
        .background(Color.background)
        .alert(alertMessage, isPresented: $showAlert) {}
        .onAppear { fetchBudgets() }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            UserProfileButton()
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
        .listRow()
        .accessibilityIdentifier("BudgetsListView.BudgetRow.\(budget.name.value)")
    }
    
    @ViewBuilder func AddBudgetButton() -> some View {
        if let count = budgets?.count {
            if count == 0 || subscriptionManager.subscriptionLevel == .boldBudgetPlus {
                NavigationLink {
                    AddBudgetView()
                } label: {
                    AddBudgetButtonLabel()
                }
                .padding()
                .accessibilityIdentifier("BudgetsListView.AddBudgetButton")
            } else {
                Button {
                    showMarketingView = true
                } label: {
                    AddBudgetButtonLabel()
                }
                .padding()
                .accessibilityIdentifier("BudgetsListView.AddBudgetButton")
                .fullScreenCover(isPresented: $showMarketingView) {
                    SubscriptionMarketingView()
                }
            }
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
            currentUserIdProvider: MockCurrentUserIdProvider(),
            subscriptionManager: MockSubscriptionLevelProvider(level: .none)
        )
    }
}

#Preview("No budgets") {
    NavigationStack {
        BudgetsListView(
            budgetFetcher: MockBudgetFetcher(budgets: []),
            currentUserIdProvider: MockCurrentUserIdProvider(),
            subscriptionManager: MockSubscriptionLevelProvider(level: .none)
        )
    }
}
