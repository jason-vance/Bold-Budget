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
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    //TODO: I should probably make this a fetcher and add refresh to this view
    private let budgetsProvider: BudgetsListBudgetsProvider
    
    init() {
        self.init(
            budgetsProvider: iocContainer~>BudgetsListBudgetsProvider.self
        )
    }
    
    init(
        budgetsProvider: BudgetsListBudgetsProvider
    ) {
        self.budgetsProvider = budgetsProvider
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
                    ForEach(budgets) { budget in
                        BudgetRow(budget)
                    }
                }
            } else {
                BlockingSpinnerView()
                    .listRowNoChrome()
            }
        }
        .safeAreaInset(edge: .bottom, alignment: .trailing) { AddBudgetButton() }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .toolbar { Toolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Budgets")
        .foregroundStyle(Color.text)
        .background(Color.background)
        .onReceive(budgetsProvider.budgetsPublisher) { budgets = $0 }
        .alert(alertMessage, isPresented: $showAlert) {}
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            UserProfileButton()
        }
    }
    
    @ViewBuilder private func BudgetRow(_ budget: BudgetInfo) -> some View {
        NavigationLink {
            DashboardView(budget: budget)
        } label: {
            Text(budget.name.value)
        }
        .listRow()
        .accessibilityIdentifier("BudgetsListView.BudgetRow.\(budget.name.value)")
    }
    
    @ViewBuilder func AddBudgetButton() -> some View {
        NavigationLink {
            AddBudgetView()
        } label: {
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
        .padding()
        .accessibilityIdentifier("BudgetsListView.AddBudgetButton")
    }
}

#Preview {
    let budgetsProvider = BudgetsListBudgetsProvider(
        userIdProvider: MockCurrentUserIdProvider(currentUserId: .sample),
        budgetsProvider: MockBudgetsProvider(budgets: [.sample])
    )
    
    NavigationStack {
        BudgetsListView(
            budgetsProvider: budgetsProvider
        )
    }
}

#Preview("No budgets") {
    let budgetsProvider = BudgetsListBudgetsProvider(
        userIdProvider: MockCurrentUserIdProvider(currentUserId: .sample),
        budgetsProvider: MockBudgetsProvider(budgets: [])
    )
    
    NavigationStack {
        BudgetsListView(
            budgetsProvider: budgetsProvider
        )
    }
}
