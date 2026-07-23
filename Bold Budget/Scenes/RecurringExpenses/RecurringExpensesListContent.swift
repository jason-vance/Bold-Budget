//
//  RecurringExpensesListContent.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/16/26.
//

import SwiftUI

/// The Spending tab's Recurring mode, redesign palette: a title header, month/debt totals, and a
/// section per kind (debts, bills, subscriptions) with a row for each expense. Self-contained (own
/// header + scroll) so it carries the redesign look without the shared List chrome, mirroring
/// `EnvelopesView`.
struct RecurringExpensesView: View {

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
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(spacing: 0) {
                    if !hasContent {
                        EmptyState()
                    } else {
                        Totals()
                            .padding(.vertical, .padding)
                        RowDivider(opacity: 0.2)
                        ForEach(RecurringExpense.Kind.allCases, id: \.self) { kind in
                            KindSection(kind)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .refreshable { budget.refresh() }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        HStack(spacing: .paddingSmall) {
            Text("Recurring Expenses")
                .font(.headline)
                .foregroundStyle(Color.appText)
            Spacer(minLength: 0)
            NavigationLink {
                BudgetSettingsView(budget: _budget)
            } label: {
                Image(systemName: "gearshape")
                    .font(.body)
                    .foregroundStyle(Color.appMutedText)
            }
            .accessibilityIdentifier("BudgetDetailView.SettingsButton")
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Totals

    @ViewBuilder private func Totals() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Expected / Month")
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .kerning(0.5)
                    .foregroundStyle(Color.appMutedText)
                Text(totalMonthly.formatted())
                    .font(.headline)
                    .foregroundStyle(Color.appText)
                    .contentTransition(.numericText())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Debt Owed")
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .kerning(0.5)
                    .foregroundStyle(Color.appMutedText)
                Text(totalOwed.formatted())
                    .font(.headline)
                    .foregroundStyle(Color.appText)
                    .contentTransition(.numericText())
            }
        }
    }

    // MARK: - Kind section

    @ViewBuilder private func KindSection(_ kind: RecurringExpense.Kind) -> some View {
        let expenses = expenses(of: kind)
        let accounts = kind == .debt ? debtAccounts : []
        if !expenses.isEmpty || !accounts.isEmpty {
            let monthly = expenses.totalMonthlyCost + accounts.totalMonthlyPayments
            VStack(spacing: 0) {
                SectionHeader(title: kind.pluralName, monthly: monthly)
                ForEach(expenses) { expense in
                    ExpenseRow(expense)
                }
                ForEach(accounts) { account in
                    AccountRow(account)
                }
            }
        }
    }

    @ViewBuilder private func SectionHeader(title: String, monthly: Money) -> some View {
        HStack {
            Text(title)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .kerning(0.5)
            Spacer()
            Text("\(monthly.formatted())/mo")
                .font(.caption2.weight(.semibold))
                .contentTransition(.numericText())
        }
        .foregroundStyle(Color.appMutedText)
        .padding(.vertical, .paddingSmall)
    }

    // MARK: - Rows

    @ViewBuilder private func AccountRow(_ account: Account) -> some View {
        NavigationLink {
            AccountDetailView(budget: budget, accountId: account.id)
        } label: {
            Row(
                systemName: account.kind.sfSymbol,
                title: account.name.value,
                subtitle: String(localized: "\(account.balance.formatted()) still owed"),
                trailing: "\((account.monthlyPayment ?? .zero).formatted())/mo"
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func ExpenseRow(_ expense: RecurringExpense) -> some View {
        NavigationLink {
            EditRecurringExpenseView(budget: budget)
                .editing(expense)
        } label: {
            Row(
                systemName: symbol(for: expense.kind),
                title: expense.name.value,
                subtitle: rowSubtitle(for: expense),
                trailing: "\(expense.monthlyCost.formatted())/mo"
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func Row(systemName: String, title: String, subtitle: String?, trailing: String) -> some View {
        HStack(spacing: .padding) {
            IconCircle(systemName: systemName, size: 40, tint: .brandTeal)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appText)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.appMutedText)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Text(trailing)
                .fontWeight(.semibold)
                .foregroundStyle(Color.appText)
                .contentTransition(.numericText())
        }
        .padding(.vertical, .padding)
        .contentShape(Rectangle())
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

    @ViewBuilder private func RowDivider(opacity: Double = 0.15) -> some View {
        Rectangle()
            .fill(Color.appMutedText.opacity(opacity))
            .frame(height: 1)
    }

    // MARK: - Empty state

    @ViewBuilder private func EmptyState() -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(systemName: "calendar.badge.clock", size: 56, tint: .brandTeal)
            Text("No Recurring Expenses")
                .font(.title3.weight(.bold))
            Text("Track debts, bills, and subscriptions to see what you owe and what each month costs you.")
                .font(.subheadline)
                .foregroundStyle(Color.appMutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .padding * 2)
    }
}

#Preview("Populated") {
    NavigationStack {
        RecurringExpensesView(budget: .previewSample(recurringExpenses: RecurringExpense.samples))
    }
}

#Preview("Empty") {
    NavigationStack {
        RecurringExpensesView(budget: .previewSample())
    }
}
