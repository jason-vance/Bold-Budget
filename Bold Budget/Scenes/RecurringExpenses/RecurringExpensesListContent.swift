//
//  RecurringExpensesListContent.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/16/26.
//

import SwiftUI

/// List `Section` content for recurring expenses, meant to be embedded inside a parent `List`
/// (mirrors `EnvelopesView`) rather than owning its own screen chrome.
struct RecurringExpensesListContent: View {

    @StateObject var budget: Budget

    private var allExpenses: [RecurringExpense] {
        Array(budget.recurringExpenses.values)
    }

    private func expenses(of kind: RecurringExpense.Kind) -> [RecurringExpense] {
        allExpenses
            .filter { $0.kind == kind }
            .sorted { $0.name.value < $1.name.value }
    }

    /// Liability accounts with a monthly payment are shown alongside recurring debts.
    private var debtAccounts: [Account] {
        budget.accounts.values
            .filter { $0.accountClass == .liability && ($0.monthlyPayment?.amount ?? 0) > 0 }
            .sorted { $0.name.value < $1.name.value }
    }

    private var hasContent: Bool {
        !allExpenses.isEmpty || !debtAccounts.isEmpty
    }

    private var totalMonthly: Money {
        allExpenses.totalMonthlyCost + debtAccounts.totalMonthlyPayments
    }

    private var totalOwed: Money {
        allExpenses.totalRemainingBalance + debtAccounts.reduce(Money.zero) { $0 + $1.balance }
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
        if !hasContent {
            NoExpensesView()
        } else {
            TotalsSection()
            ForEach(RecurringExpense.Kind.allCases, id: \.self) { kind in
                KindSection(kind)
            }
        }
    }

    @ViewBuilder private func TotalsSection() -> some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Expected / Month")
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(Color.text.opacity(0.5))
                    Text(totalMonthly.formatted())
                        .foregroundStyle(Color.text)
                        .contentTransition(.numericText())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Debt Owed")
                        .font(.caption2.bold())
                        .textCase(.uppercase)
                        .foregroundStyle(Color.text.opacity(0.5))
                    Text(totalOwed.formatted())
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
        let accounts = kind == .debt ? debtAccounts : []
        if !expenses.isEmpty || !accounts.isEmpty {
            let monthly = expenses.totalMonthlyCost + accounts.totalMonthlyPayments
            Section {
                ForEach(expenses) { expense in
                    ExpenseRow(expense)
                }
                ForEach(accounts) { account in
                    AccountRow(account)
                }
            } header: {
                HStack {
                    Text(kind.pluralName)
                    Spacer()
                    Text("\(monthly.formatted())/mo")
                }
                .foregroundStyle(Color.text)
            }
            .listSectionSeparator(.hidden)
            .listSectionSpacing(0)
        }
    }

    @ViewBuilder private func AccountRow(_ account: Account) -> some View {
        NavigationLink {
            EditAccountView(budget: budget).editing(account)
        } label: {
            HStack(spacing: .padding) {
                IconCircle(systemName: account.kind.sfSymbol, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name.value)
                        .fontWeight(.semibold)
                    Text("\(account.balance.formatted()) still owed")
                        .font(.caption)
                        .foregroundStyle(Color.text.opacity(.opacityMutedText))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Text("\((account.monthlyPayment ?? .zero).formatted())/mo")
                    .fontWeight(.semibold)
                    .contentTransition(.numericText())
            }
        }
        .listRow()
    }

    @ViewBuilder private func ExpenseRow(_ expense: RecurringExpense) -> some View {
        NavigationLink {
            EditRecurringExpenseView(budget: budget)
                .editing(expense)
        } label: {
            HStack(spacing: .padding) {
                IconCircle(systemName: symbol(for: expense.kind), size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.name.value)
                        .fontWeight(.semibold)
                    if let subtitle = rowSubtitle(for: expense) {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    }
                }
                Spacer(minLength: 0)
                Text("\(expense.monthlyCost.formatted())/mo")
                    .fontWeight(.semibold)
                    .contentTransition(.numericText())
            }
        }
        .listRow()
    }

    private func symbol(for kind: RecurringExpense.Kind) -> String {
        switch kind {
        case .debt: "creditcard.fill"
        case .bill: "doc.text.fill"
        case .subscription: "arrow.triangle.2.circlepath"
        }
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
}

#Preview("Populated") {
    List {
        RecurringExpensesListContent(budget: .previewSample(recurringExpenses: RecurringExpense.samples))
    }
    .listStyle(.insetGrouped)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .foregroundStyle(Color.text)
    .background(Color.background)
}

#Preview("Empty") {
    List {
        RecurringExpensesListContent(budget: .previewSample())
    }
    .listStyle(.insetGrouped)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .foregroundStyle(Color.text)
    .background(Color.background)
}
