//
//  EnvelopesView.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/13/26.
//

import SwiftUI

/// The Spending tab's Envelopes mode, redesign palette: timeframe header, income/expense totals, and
/// a row per category showing its goal progress. Selecting an envelope collapses the list down to
/// just that envelope — animated to the top — and reveals its transactions row by row; deselecting
/// (or the header back button) reverses it. Self-contained (own header + scroll) so it carries the
/// redesign look without the shared List chrome.
struct EnvelopesView: View {

    struct Category: Identifiable {
        var id: Transaction.Category.Id { category.id }
        let category: Transaction.Category
        let transactions: [Transaction]

        /// Categories are no longer income/expense-typed, so an envelope is treated as income
        /// only when every transaction in it is income.
        var isIncome: Bool {
            !transactions.isEmpty && transactions.allSatisfy { $0.kind == .income }
        }
    }

    @StateObject var budget: Budget
    @Binding var timeFrame: TimeFrame
    @Binding var transactionsFilter: TransactionsFilter

    @State private var selectedCategory: Transaction.Category?
    @State private var showPeriodPicker = false
    @State private var showFilter = false

    var displayCategories: [Category] {
        budget.transactionsByCategory
            .map(Category.init)
            .sorted { $0.category.name.value < $1.category.name.value }
            .sorted { $0.category.goal != nil && $1.category.goal == nil }
            .sorted { $0.isIncome && !$1.isIncome }
    }

    /// The envelopes currently in the list: every envelope, or — once one is selected — only it.
    private var visibleCategories: [Category] {
        guard let selectedCategory else { return displayCategories }
        return displayCategories.filter { $0.category == selectedCategory }
    }

    private var selectedTransactions: [Transaction] {
        guard let selectedCategory,
              let category = displayCategories.first(where: { $0.category == selectedCategory })
        else { return [] }
        return timeFramedTransactions(category)
    }

    private func timeFramedTransactions(_ category: Category) -> [Transaction] {
        category.transactions
            .filter { $0.date >= timeFrame.start && $0.date <= timeFrame.end }
            .sorted { $0.date > $1.date }
    }

    private var filteredTransactions: [Transaction] {
        budget.transactions.values.filter {
            $0.date >= timeFrame.start &&
            $0.date <= timeFrame.end &&
            transactionsFilter.shouldInclude($0, from: budget)
        }
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
                VStack(spacing: 0) {
                    Totals()
                        .padding(.vertical, .padding)
                    RowDivider(opacity: 0.2)
                    if displayCategories.isEmpty {
                        EmptyEnvelopes()
                    } else {
                        ForEach(Array(visibleCategories.enumerated()), id: \.element.id) { index, category in
                            EnvelopeRow(category, showTopDivider: index > 0)
                                .transition(.opacity)
                        }
                        ForEach(Array(selectedTransactions.enumerated()), id: \.element.id) { index, transaction in
                            TransactionRow(transaction)
                                .transition(transactionTransition(index: index))
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
        .overlay(alignment: .top) { PeriodDropdown() }
        .overlay(alignment: .top) { FilterDropdown() }
    }

    private func select(_ category: Transaction.Category) {
        withAnimation(.snappy) {
            selectedCategory = (selectedCategory == category) ? nil : category
        }
    }

    private func deselect() {
        withAnimation(.snappy) { selectedCategory = nil }
    }

    /// Transactions reveal top-to-bottom on selection with a quick, capped stagger; deselecting
    /// hides them immediately (no removal animation).
    private func transactionTransition(index: Int) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity)
                .animation(.snappy.delay(min(Double(index) * 0.02, 0.15))),
            removal: .identity
        )
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        HStack(spacing: .paddingSmall) {
            if selectedCategory != nil {
                Button { deselect() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                }
                .accessibilityIdentifier("EnvelopesView.BackButton")
            } else {
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
            }

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

    // MARK: - Dropdowns

    /// The transaction filter as a panel dropping in under the header, over the content.
    @ViewBuilder private func FilterDropdown() -> some View {
        if showFilter {
            ZStack(alignment: .top) {
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

    /// The timeframe picker as a panel dropping in under the header, over the content.
    @ViewBuilder private func PeriodDropdown() -> some View {
        if showPeriodPicker {
            ZStack(alignment: .top) {
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

    // MARK: - Envelope row

    @ViewBuilder private func EnvelopeRow(_ category: Category, showTopDivider: Bool) -> some View {
        let transactions = timeFramedTransactions(category)
        let totalAmount = transactions.reduce(Money.zero) { $0 + $1.amount }
        let isSelected = selectedCategory == category.category

        Button {
            select(category.category)
        } label: {
            VStack(spacing: 0) {
                if showTopDivider { RowDivider() }
                VStack(spacing: .paddingSmall) {
                    RowHeader(category: category, totalAmount: totalAmount)
                    if let goal = category.category.goal {
                        GoalProgressBar(goal: goal, totalAmount: totalAmount)
                    }
                    RowStatus(
                        category: category.category,
                        totalAmount: totalAmount,
                        transactionCount: transactions.count,
                        isSelected: isSelected
                    )
                }
                .padding(.vertical, .padding)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func RowHeader(category: Category, totalAmount: Money) -> some View {
        HStack(spacing: .padding) {
            IconCircle(systemName: category.category.sfSymbol.value, size: 40, tint: .brandTeal)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.category.name.value)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appText)
                if let goal = category.category.goal {
                    Text("Goal: \(goal.comparison == .lessThan ? "<" : "≥") \(goal.amount.formattedRounded())/\(goal.period.toUiString())")
                        .font(.caption)
                        .foregroundStyle(Color.appMutedText)
                }
            }
            Spacer(minLength: 0)
            Text("\(category.isIncome ? "+" : "")\(totalAmount.formattedRounded())")
                .font(.title3.weight(.heavy))
                .foregroundStyle(category.isIncome ? Color.positive : Color.appText)
                .contentTransition(.numericText())
        }
    }

    @ViewBuilder private func GoalProgressBar(goal: Transaction.Category.Goal, totalAmount: Money) -> some View {
        let multiplier = goal.period.number(in: timeFrame.period)
        let goalAmount = goal.amount * multiplier
        let isOverLimit = goal.comparison == .lessThan && totalAmount.amount > goalAmount.amount
        let fraction: Double = {
            guard goalAmount.amount > 0 else { return 0 }
            return isOverLimit ? 1 : min(totalAmount.amount / goalAmount.amount, 1)
        }()
        let fill = isOverLimit ? Color.negative : Color.brandTeal

        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().foregroundStyle(Color.appMutedText.opacity(0.2))
                Capsule().foregroundStyle(fill).frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 8)
    }

    @ViewBuilder private func RowStatus(category: Transaction.Category, totalAmount: Money, transactionCount: Int, isSelected: Bool) -> some View {
        HStack {
            if let goal = category.goal {
                let multiplier = goal.period.number(in: timeFrame.period)
                let goalAmount = goal.amount * multiplier

                // For a "less than" goal, going over is the problem to flag; for a
                // "greater than" goal, falling short is.
                if goal.comparison == .lessThan {
                    if let overAmount = totalAmount - goalAmount {
                        Text("\(overAmount.formattedRounded()) over goal")
                            .foregroundStyle(Color.negative)
                    } else if let underAmount = goalAmount - totalAmount {
                        Text("\(underAmount.formattedRounded()) left")
                            .foregroundStyle(Color.appMutedText)
                    }
                } else {
                    if let overAmount = totalAmount - goalAmount {
                        Text("Goal reached · +\(overAmount.formattedRounded())")
                            .foregroundStyle(Color.positive)
                    } else if let underAmount = goalAmount - totalAmount {
                        Text("\(underAmount.formattedRounded()) to go")
                            .foregroundStyle(Color.brandTeal)
                    }
                }
            }
            Spacer(minLength: 0)
            Text("\(transactionCount) \(transactionCount == 1 ? "transaction" : "transactions")")
                .foregroundStyle(Color.appMutedText)
            if transactionCount > 0 {
                Text(isSelected ? "Hide" : "Show")
                    .foregroundStyle(Color.brandTeal)
            }
        }
        .font(.caption.weight(.semibold))
    }

    // MARK: - Transaction row

    @ViewBuilder private func TransactionRow(_ transaction: Transaction) -> some View {
        VStack(spacing: 0) {
            RowDivider()
            NavigationLink {
                TransactionDetailView(budget: budget, transaction: transaction)
            } label: {
                TransactionRowView(
                    budget: budget,
                    transaction: transaction,
                    category: budget.getCategoryBy(id: transaction.categoryId)
                )
                .padding(.vertical, .padding)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder private func RowDivider(opacity: Double = 0.15) -> some View {
        Rectangle()
            .fill(Color.appMutedText.opacity(opacity))
            .frame(height: 1)
    }

    @ViewBuilder private func EmptyEnvelopes() -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(systemName: "envelope", size: 56, tint: .brandTeal)
            Text("No Envelopes")
                .font(.title3.weight(.bold))
            Text("Categorize your transactions and they'll be grouped into envelopes here.")
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
        EnvelopesView(
            budget: .previewSample(transactions: Transaction.screenshotSamples),
            timeFrame: .constant(.init(period: .year, containing: .now)),
            transactionsFilter: .constant(.none)
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        EnvelopesView(
            budget: .previewSample(),
            timeFrame: .constant(.init(period: .year, containing: .now)),
            transactionsFilter: .constant(.none)
        )
    }
}
