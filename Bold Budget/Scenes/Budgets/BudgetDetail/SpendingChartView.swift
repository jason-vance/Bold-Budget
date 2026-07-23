//
//  SpendingChartView.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/22/26.
//

import SwiftUI

/// The Spending tab's Chart mode, redesign palette: timeframe header, donut with center total,
/// income/expense totals, and the transaction list. Self-contained (own header + scroll) so it can
/// carry the redesign look without the shared List chrome.
struct SpendingChartView: View {

    @StateObject var budget: Budget
    @Binding var timeFrame: TimeFrame
    @Binding var transactionsFilter: TransactionsFilter

    @State private var showPeriodPicker = false
    @State private var showFilter = false

    private struct Group: Identifiable {
        var id: SimpleDate { date }
        let date: SimpleDate
        let transactions: [Transaction]
    }

    private var filteredTransactions: [Transaction] {
        budget.transactions.values.filter {
            $0.date >= timeFrame.start &&
            $0.date <= timeFrame.end &&
            transactionsFilter.shouldInclude($0, from: budget)
        }
    }

    private var groups: [Group] {
        Dictionary(grouping: filteredTransactions, by: \.date)
            .map { Group(date: $0.key, transactions: $0.value) }
            .sorted { $0.date > $1.date }
    }

    private var pieSlices: [PieChart.Slice] {
        struct Key: Hashable { let categoryId: Transaction.Category.Id; let kind: Transaction.Kind }
        var dict = [Key: Money]()
        for t in filteredTransactions where !t.isTransfer {
            let key = Key(categoryId: t.categoryId, kind: t.kind)
            dict[key] = dict[key, default: .zero] + t.amount
        }
        return dict.map { key, value in
            PieChart.Slice(value: value.amount, category: budget.getCategoryBy(id: key.categoryId), kind: key.kind)
        }
    }

    private func formatPieChart(value: Double) -> String {
        if let money = Money(value) { money.formattedRounded() }
        else if let negative = Money(-value) { "-\(negative.formattedRounded())" }
        else { value.formatted() }
    }

    private var income: Money {
        filteredTransactions.filter { $0.kind == .income }.reduce(into: .zero) { $0 = $0 + $1.amount }
    }

    private var expenses: Money {
        filteredTransactions.filter { $0.kind == .expense }.reduce(into: .zero) { $0 = $0 + $1.amount }
    }

    var body: some View {
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(spacing: .padding) {
                    if !pieSlices.isEmpty {
                        PieChart(slices: pieSlices)
                            .valueFormatter { formatPieChart(value: $0) }
                            .containerRelativeFrame(.horizontal) { length, _ in length * 0.7 }
                    }
                    Totals()
                    Divider().overlay(Color.appMutedText.opacity(0.3))
                    TransactionsList()
                }
                .padding()
            }
            .refreshable { budget.refresh() }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .overlay(alignment: .top) { PeriodDropdown() }
        .overlay(alignment: .top) { FilterDropdown() }
    }

    // MARK: - Filter dropdown

    /// The transaction filter as a panel dropping in under the toolbar, over the content — the same
    /// presentation the timeframe picker landed on, instead of a bottom sheet.
    @ViewBuilder private func FilterDropdown() -> some View {
        if showFilter {
            ZStack(alignment: .top) {
                // Full-screen tap-catcher to dismiss when tapping outside the panel.
                Rectangle()
                    .fill(Color.appBackground.opacity(0.01))
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.snappy) { showFilter = false } }

                TransactionsFilterMenu(
                    budget: budget,
                    isMenuVisible: $showFilter,
                    transactionsFilter: $transactionsFilter,
                    transactionCount: .init(get: { filteredTransactions.count }, set: { _ in })
                )
                .background(Color.appBackground)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.appMutedText.opacity(0.2)).frame(height: 1)
                }
                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                .padding(.top, .barHeight)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Period dropdown

    /// The timeframe picker as a panel dropping in under the toolbar, over the content. Anchored at
    /// the top so switching periods only grows/shrinks the bottom, keeping it stable.
    @ViewBuilder private func PeriodDropdown() -> some View {
        if showPeriodPicker {
            ZStack(alignment: .top) {
                // Full-screen tap-catcher to dismiss when tapping outside the panel.
                Rectangle()
                    .fill(Color.appBackground.opacity(0.01))
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.snappy) { showPeriodPicker = false } }

                TimeFramePicker(budget: budget, timeFrame: $timeFrame)
                    .background(Color.appBackground)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Color.appMutedText.opacity(0.2)).frame(height: 1)
                    }
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                    .padding(.top, .barHeight)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        HStack(spacing: .paddingSmall) {
            Button {
                withAnimation(.snappy) {
                    showFilter.toggle()
                    if showFilter { showPeriodPicker = false }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(transactionsFilter.count > 0 ? Color.brandTeal : Color.appMutedText)
                    .overlay(alignment: .topTrailing) {
                        if transactionsFilter.count > 0 {
                            Circle().fill(Color.brandTeal).frame(width: 6, height: 6).offset(x: 4, y: -3)
                        }
                    }
            }
            .accessibilityIdentifier("DashboardView.FilterTransactionsButton")

            Spacer(minLength: 0)

            HStack(spacing: .paddingSmall) {
                StepButton(systemName: "chevron.left", disabled: !canGoBack) { timeFrame = timeFrame.previous }
                Button {
                    withAnimation(.snappy) {
                        showPeriodPicker.toggle()
                        if showPeriodPicker { showFilter = false }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(timeFrame.toUiString())
                            .font(.headline)
                            .foregroundStyle(Color.appText)
                            .contentTransition(.numericText())
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.appMutedText)
                            .rotationEffect(.degrees(showPeriodPicker ? 180 : 0))
                    }
                    .frame(minWidth: timeFrame.period == .week ? nil : 120)
                }
                StepButton(systemName: "chevron.right", disabled: !canGoForward) { timeFrame = timeFrame.next }
            }

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

    private var canGoBack: Bool {
        budget.transactions.values.contains { $0.date <= timeFrame.previous.end }
    }

    private var canGoForward: Bool {
        budget.transactions.values.contains { $0.date >= timeFrame.next.start }
    }

    @ViewBuilder private func StepButton(systemName: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy) { action() }
        } label: {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.appMutedText)
                .opacity(disabled ? 0.3 : 1)
                .frame(width: 32, height: 32)
        }
        .disabled(disabled)
    }

    // MARK: - Totals

    @ViewBuilder private func Totals() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Income")
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .kerning(0.5)
                    .foregroundStyle(Color.appMutedText)
                Text(income.formattedRounded())
                    .font(.headline)
                    .foregroundStyle(income.amount > 0 ? Color.positive : Color.appText)
                    .contentTransition(.numericText())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Expenses")
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .kerning(0.5)
                    .foregroundStyle(Color.appMutedText)
                Text(expenses.formattedRounded())
                    .font(.headline)
                    .foregroundStyle(Color.appText)
                    .contentTransition(.numericText())
            }
        }
    }

    // MARK: - Transactions

    @ViewBuilder private func TransactionsList() -> some View {
        if groups.isEmpty {
            EmptyTransactions()
        } else {
            ForEach(groups) { group in
                VStack(spacing: .paddingSmall) {
                    HStack {
                        Text(group.date.toDate()?.toBasicUiString() ?? "—")
                        Spacer()
                        Text(groupSum(group))
                    }
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .kerning(0.6)
                    .foregroundStyle(Color.appMutedText)

                    VStack(spacing: 0) {
                        let sorted = group.transactions.sorted { budget.description(of: $0) < budget.description(of: $1) }
                        ForEach(sorted) { transaction in
                            NavigationLink {
                                TransactionDetailView(budget: budget, transaction: transaction)
                            } label: {
                                TransactionRowView(
                                    budget: budget,
                                    transaction: transaction,
                                    category: budget.getCategoryBy(id: transaction.categoryId),
                                    showsDate: false
                                )
                                .padding(.vertical, .paddingSmall)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func groupSum(_ group: Group) -> String {
        let sum = group.transactions.reduce(0.0) {
            guard !$1.isTransfer else { return $0 }
            return $0 + (($1.kind == .income ? 1.0 : -1.0) * $1.amount.amount)
        }
        guard let money = Money(abs(sum)) else { return "" }
        return sum > 0 ? "+\(money.formatted())" : money.formatted()
    }

    @ViewBuilder private func EmptyTransactions() -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(systemName: "dollarsign", size: 56, tint: .brandTeal)
            Text("No Transactions")
                .font(.title3.weight(.bold))
            Text(budget.transactions.isEmpty
                 ? "Any transactions you add will show up here."
                 : "There are no transactions in this time period.")
                .font(.subheadline)
                .foregroundStyle(Color.appMutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .padding * 2)
    }
}
