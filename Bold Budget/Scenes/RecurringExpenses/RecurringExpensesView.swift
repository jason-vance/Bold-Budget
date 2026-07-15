//
//  RecurringExpensesView.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/15/26.
//

import SwiftUI
import SwinjectAutoregistration

struct RecurringExpensesView: View {

    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    @StateObject var budget: Budget

    @State private var subscriptionLevel: SubscriptionLevel = .none
    private let subscriptionLevelProvider: SubscriptionLevelProvider

    init(budget: Budget) {
        self.init(
            budget: budget,
            subscriptionLevelProvider: iocContainer~>SubscriptionLevelProvider.self
        )
    }

    init(
        budget: Budget,
        subscriptionLevelProvider: SubscriptionLevelProvider
    ) {
        self._budget = .init(wrappedValue: budget)
        self.subscriptionLevelProvider = subscriptionLevelProvider
    }

    private var allExpenses: [RecurringExpense] {
        Array(budget.recurringExpenses.values)
    }

    private func expenses(of kind: RecurringExpense.Kind) -> [RecurringExpense] {
        allExpenses
            .filter { $0.kind == kind }
            .sorted { $0.name.value < $1.name.value }
    }

    private func billingNote(for expense: RecurringExpense) -> String? {
        switch expense.monthsPerCycle {
        case 1:
            nil
        case 12:
            String(localized: "\(expense.price.formatted())/yr")
        default:
            String(localized: "\(expense.price.formatted()) every \(expense.monthsPerCycle) months")
        }
    }

    var body: some View {
        List {
            AdSection()
            if allExpenses.isEmpty {
                NoExpensesView()
            } else {
                TotalsSection()
                ForEach(RecurringExpense.Kind.allCases, id: \.self) { kind in
                    KindSection(kind)
                }
            }
        }
        .refreshable { budget.refresh() }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottomTrailing) { AddExpenseButton() }
        .navigationTitle("Recurring Expenses")
        .navigationBarTitleDisplayMode(.inline)
        .foregroundStyle(Color.text)
        .background(Color.background.ignoresSafeArea())
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .animation(.snappy, value: budget.recurringExpenses)
        .onReceive(subscriptionLevelProvider.subscriptionLevelPublisher) { subscriptionLevel = $0 }
    }

    @ViewBuilder private func TotalsSection() -> some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Expected / Month")
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(Color.text.opacity(0.5))
                    Text(allExpenses.totalMonthlyCost.formatted())
                        .foregroundStyle(Color.text)
                        .contentTransition(.numericText())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Debt Owed")
                        .font(.caption2.bold())
                        .textCase(.uppercase)
                        .foregroundStyle(Color.text.opacity(0.5))
                    Text(allExpenses.totalRemainingBalance.formatted())
                        .foregroundStyle(Color.text)
                        .contentTransition(.numericText())
                }
            }
            .listRowBackground(Color.background)
            .listRowSeparator(.hidden)
        }
        .listSectionSeparator(.hidden)
        .listSectionSpacing(0)
    }

    @ViewBuilder private func KindSection(_ kind: RecurringExpense.Kind) -> some View {
        let expenses = expenses(of: kind)
        if !expenses.isEmpty {
            Section {
                ForEach(expenses) { expense in
                    ExpenseRow(expense)
                }
            } header: {
                HStack {
                    Text(kind.pluralName)
                    Spacer()
                    Text("\(expenses.totalMonthlyCost.formatted())/mo")
                }
                .foregroundStyle(Color.text)
            }
            .listSectionSeparator(.hidden)
            .listSectionSpacing(0)
        }
    }

    @ViewBuilder private func ExpenseRow(_ expense: RecurringExpense) -> some View {
        NavigationLink {
            EditRecurringExpenseView(budget: budget)
                .editing(expense)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.name.value)
                    if let subtitle = rowSubtitle(for: expense) {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    }
                }
                Spacer(minLength: 0)
                Text("\(expense.monthlyCost.formatted())/mo")
                    .contentTransition(.numericText())
            }
        }
        .listRow()
    }

    private func rowSubtitle(for expense: RecurringExpense) -> String? {
        if expense.kind == .debt, let balance = expense.remainingBalance {
            return String(localized: "\(balance.formatted()) still owed")
        }
        return billingNote(for: expense)
    }

    @ViewBuilder private func NoExpensesView() -> some View {
        ContentUnavailableView(
            "No Recurring Expenses",
            systemImage: "calendar.badge.clock",
            description: Text("Track debts, bills, and subscriptions to see what you owe and what each month costs you")
        )
        .listRowBackground(Color.background)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder private func AddExpenseButton() -> some View {
        NavigationLink {
            EditRecurringExpenseView(budget: budget)
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
        .accessibilityIdentifier("RecurringExpensesView.AddExpenseButton")
    }

    @ViewBuilder private func AdSection() -> some View {
        if subscriptionLevel == SubscriptionLevel.none {
            Section {
                NativeAdListRow(ad: $ad, size: .small)
                    .listRow()
            }
        }
    }
}

#Preview("Populated") {
    NavigationStack {
        RecurringExpensesView(
            budget: .previewSample(recurringExpenses: RecurringExpense.samples),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}

#Preview("Empty") {
    NavigationStack {
        RecurringExpensesView(
            budget: .previewSample(),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}
