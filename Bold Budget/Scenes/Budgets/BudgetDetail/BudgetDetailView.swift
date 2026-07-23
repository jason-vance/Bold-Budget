//
//  BudgetDetailView.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import SwiftUI
import SwinjectAutoregistration
import Combine

struct BudgetDetailView: View {
    
    /// Top-level destinations in the bottom bar. `Add` sits between them as the primary action.
    private enum TopTab: String {
        case spending
        case netWorth

        var sfSymbol: String {
            switch self {
            case .spending: "chart.pie"
            case .netWorth: "chart.line.uptrend.xyaxis"
            }
        }

        var label: String {
            switch self {
            case .spending: String(localized: "Spending")
            case .netWorth: String(localized: "Net Worth")
            }
        }
    }

    /// Sub-modes within the Spending tab.
    private enum ViewMode: String {
        case pieChart
        case envelopes
        case recurringExpenses

        var sfSymbol: String {
            switch self {
            case .pieChart: "chart.pie"
            case .envelopes: "envelope"
            case .recurringExpenses: "calendar.badge.clock"
            }
        }

        var label: String {
            switch self {
            case .pieChart: String(localized: "Chart")
            case .envelopes: String(localized: "Envelopes")
            case .recurringExpenses: String(localized: "Recurring")
            }
        }

        /// View modes that summarize spending over a time frame, vs. standalone ledgers.
        var isTimeFramed: Bool {
            switch self {
            case .pieChart, .envelopes: true
            case .recurringExpenses: false
            }
        }
    }
    
    private enum ExtraOptionsMenu {
        case timeFrame
        case transactionFilters
    }
    
    struct TransactionGroup: Identifiable {
        var id: SimpleDate { date }
        let date: SimpleDate
        var transactions: [Transaction]
        
        @MainActor
        func formattedAmountSum(budget: Budget) -> String {
            let sum: Double = transactions.reduce(0) {
                guard !$1.isTransfer else { return $0 }
                let sign = ($1.kind == .income) ? 1.0 : -1.0
                return $0 + (sign * $1.amount.amount)
            }
            
            if let money = Money(abs(sum)) {
                return sum > 0 ? "+\(money.formatted())" : money.formatted()
            }
            return ""
        }
    }
    
    @Environment(\.requestReview) var requestReview
    @Environment(\.scenePhase) private var scenePhase
    
    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?
    
    @AppStorage("previouslyOpenedDate") private var previouslyOpenedDateInt: Int = 0
    @AppStorage("topTab") private var topTab: TopTab = .spending
    @AppStorage("viewMode") private var viewMode: ViewMode = .pieChart
    @AppStorage("previousTimeFramePeriod") private var previousTimeFramePeriod: TimeFrame.Period = .month
    @AppStorage("previousTimeFrameDate") private var previousTimeFrameDate: Int = Int(SimpleDate.now.rawValue)

    @StateObject var budget: Budget
    
    @State private var currentUserData: UserData? = nil
    // Persistence is done via `.onChange(of:)` below, not a `didSet`: the timeframe is now mutated
    // through the `$timeFrame` binding passed to the Spending chart / picker, and `didSet` on a
    // `@State` does not fire for writes that come through a binding.
    @State private var timeFrame: TimeFrame = .init(period: .month, containing: .now)
    @State private var transactionsFilter: TransactionsFilter = .none
    
    @State private var subscriptionLevel: SubscriptionLevel? = nil
    @State private var showTimeFramePicker: Bool = false
    @State private var showFilterTransactionsOptions: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    private let subscriptionManager: SubscriptionLevelProvider
    
    init(budget: Budget) {
        self.init(
            budget: budget,
            subscriptionManager: iocContainer~>SubscriptionLevelProvider.self
        )
    }
    
    init(
        budget: Budget,
        subscriptionManager: SubscriptionLevelProvider
    ) {
        self._budget = .init(wrappedValue: budget)
        self.subscriptionManager = subscriptionManager
    }
    
    private var filteredTransactions: [Transaction] {
        budget.transactions.values
            .filter {
                $0.date >= timeFrame.start &&
                $0.date <= timeFrame.end &&
                transactionsFilter.shouldInclude($0, from: budget)
            }
    }
    
    private var transactionGroups: [TransactionGroup] {
        let dict = filteredTransactions
            .reduce(Dictionary<SimpleDate,[Transaction]>()) { dict, transaction in
                let date = transaction.date
                var dict = dict
                dict[date] = dict[date, default: []] + [transaction]
                return dict
            }
        
        return dict.map { key, value in
            TransactionGroup(date: key, transactions: value)
        }
        .sorted { $0.date > $1.date }
    }
    
    private var pieSlices: [PieChart.Slice] {
        // Key by category *and* kind: a category can now hold both income and expense
        // transactions, and the pie separates them into distinct slices.
        struct SliceKey: Hashable {
            let categoryId: Transaction.Category.Id
            let kind: Transaction.Kind
        }

        var sliceDict = [SliceKey:Money]()

        for transaction in filteredTransactions where !transaction.isTransfer {
            let key = SliceKey(categoryId: transaction.categoryId, kind: transaction.kind)
            sliceDict[key] = sliceDict[key, default: .zero] + transaction.amount
        }

        return sliceDict.map { key, value in
            PieChart.Slice(
                value: value.amount,
                category: budget.getCategoryBy(id: key.categoryId),
                kind: key.kind
            )
        }
    }
    
    private func formatPieChart(value: Double) -> String {
        if let money = Money(value) {
            money.formatted()
        } else if let negativeMoney = Money(-value) {
            "-\(negativeMoney.formatted())"
        } else {
            value.formatted()
        }
    }
    
    private var showExtraOptionsMenu: Bool {
        showTimeFramePicker || showFilterTransactionsOptions
    }
    
    private func toggle(extraOptionsMenu: ExtraOptionsMenu) {
        withAnimation(.snappy) {
            showTimeFramePicker = extraOptionsMenu == .timeFrame && !showTimeFramePicker
            showFilterTransactionsOptions = extraOptionsMenu == .transactionFilters && !showFilterTransactionsOptions
        }
    }
    
    private func hideExtraOptionsMenu() {
        withAnimation(.snappy) {
            showTimeFramePicker = false
            showFilterTransactionsOptions = false
        }
    }
    
    private func promptForReview() {
        guard let reviewPrompter = iocContainer.resolve(ReviewPrompter.self) else { return }
        reviewPrompter.promptForReviewIfAppropriate(promptForReview: requestReview)
    }
    
    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }
    
    // This func keeps `date` up to date when opening the app. Basically,
    // if you open the app on a different day than you last closed it then `date` will be .today
    private func onChangeOf(scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            if SimpleDate(rawValue: SimpleDate.RawValue(previouslyOpenedDateInt)) != .now {
                timeFrame = .init(period: previousTimeFramePeriod, containing: .now)
            }
            break
        case .background:
            previouslyOpenedDateInt = Int(SimpleDate.now.rawValue)
        default:
            break
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if topTab == .netWorth {
                NetWorthView(budget: budget)
                    .overlay {
                        if budget.isLoading { BlockingSpinnerView() }
                    }
            } else {
                SpendingContent()
            }
            BottomTabBar()
        }
        .navigationTitle(budget.info.name.value)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar { Toolbar() }
        .foregroundStyle(chromeText)
        .background(chromeBackground.ignoresSafeArea())
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .alert(alertMessage, isPresented: $showAlert) {}
        .animation(.snappy, value: budget.isLoading)
        .animation(.snappy, value: viewMode)
        .animation(.snappy, value: topTab)
        .onAppear { promptForReview() }
        .onAppear { timeFrame = .init(period: previousTimeFramePeriod, containing: SimpleDate(rawValue: SimpleDate.RawValue(previousTimeFrameDate))!) }
        .onChange(of: timeFrame) { _, timeFrame in
            previousTimeFramePeriod = timeFrame.period
            previousTimeFrameDate = Int(timeFrame.start.rawValue)
        }
        .onReceive(subscriptionManager.subscriptionLevelPublisher) { subscriptionLevel = $0 }
        .onChange(of: scenePhase) { old, new in onChangeOf(scenePhase: new) }
    }

    // The chrome (bottom bar, mode switcher) uses the redesign (black/white) tokens.
    private var chromeBackground: Color { .appBackground }
    private var chromeText: Color { .appText }
    private var chromeMuted: Color { .appMutedText }

    @ViewBuilder private func SpendingContent() -> some View {
        if viewMode == .pieChart {
            SpendingChartView(
                budget: budget,
                timeFrame: $timeFrame,
                transactionsFilter: $transactionsFilter
            )
            .overlay {
                if budget.isLoading { BlockingSpinnerView() }
            }
            SpendingModeBar()
        } else if viewMode == .envelopes {
            EnvelopesView(
                budget: budget,
                timeFrame: $timeFrame,
                transactionsFilter: $transactionsFilter
            )
            .overlay {
                if budget.isLoading { BlockingSpinnerView() }
            }
            SpendingModeBar()
        } else {
            RecurringExpensesView(budget: budget)
                .overlay {
                    if budget.isLoading { BlockingSpinnerView() }
                }
            SpendingModeBar()
        }
    }

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            SettingsButton()
        }
    }

    @ViewBuilder private func SettingsButton() -> some View {
        NavigationLink {
            BudgetSettingsView(budget: _budget)
        } label: {
            Image(systemName: "gearshape")
        }
        .accessibilityIdentifier("BudgetDetailView.SettingsButton")
    }
    
    @ViewBuilder private func NewBudgetDialogSheet() -> some View {
        EditBudgetView()
            .presentationBackground(Color.background)
            .presentationDragIndicator(.visible)
            .presentationDetents([.large])
    }
    
    @ViewBuilder private func ExtraOptionsMenuOverlay() -> some View {
        if showExtraOptionsMenu {
            VStack(spacing: 0) {
                if showFilterTransactionsOptions {
                    TransactionsFilterMenu(
                        budget: budget,
                        isMenuVisible: $showFilterTransactionsOptions,
                        transactionsFilter: $transactionsFilter,
                        transactionCount: .init(get: { filteredTransactions.count }, set: {_ in})
                    )
                } else if showTimeFramePicker {
                    TimeFramePicker(
                        budget: budget,
                        timeFrame: .init(
                            get: { timeFrame },
                            set: { timeFrame in withAnimation(.snappy) { self.timeFrame = timeFrame } }
                    ))
                }
                BarDivider()
                BarDivider() // For some reason this is not visible unless there are two of them
                Spacer(minLength: 0)
            }
            .background {
                let colors = [
                    Color.background.opacity(0.85),
                    Color.background.opacity(0.65),
                    Color.background.opacity(0.45),
                    Color.background.opacity(0.25),
                    Color.clear,
                ]
                LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                    .onTapGesture { hideExtraOptionsMenu() }
            }
            .transition(.asymmetric(insertion: .push(from: .top), removal: .push(from: .bottom)))
        }
    }
    
    @ViewBuilder func TopBar() -> some View {
        if topTab == .netWorth {
            ScreenTitleBar("Net Worth")
        } else if viewMode == .recurringExpenses {
            ScreenTitleBar("Recurring Expenses")
        } else {
            ScreenTitleBar(
                primaryContent: {
                    TimeFrameButton()
                },
                leadingContent: {
                    EmptyView()
                },
                trailingContent: {
                    FilterTransactionsButton()
                        .accessibilityIdentifier("DashboardView.FilterTransactionsButton")
                }
            )
        }
    }

    /// Secondary switcher for the Spending tab's sub-modes (Chart / Envelopes / Recurring).
    @ViewBuilder private func SpendingModeBar() -> some View {
        HStack(spacing: .paddingSmall) {
            SpendingModeButton(.pieChart)
            SpendingModeButton(.envelopes)
            SpendingModeButton(.recurringExpenses)
        }
        .padding(.horizontal, .padding)
        .padding(.vertical, .paddingSmall)
        .background(chromeBackground)
        .overlay(alignment: .top) { BarDivider() }
    }

    @ViewBuilder private func SpendingModeButton(_ mode: ViewMode) -> some View {
        let isSelected = viewMode == mode
        Button {
            withAnimation(.snappy) { viewMode = mode }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: mode.sfSymbol)
                    .font(.caption)
                Text(mode.label)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : chromeText)
            .padding(.vertical, .paddingSmall)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .foregroundStyle(isSelected ? Color.brandTeal : chromeText.opacity(.opacityButtonBackground))
            }
        }
        .accessibilityIdentifier("BudgetDetailView.SpendingModeBar.\(mode.rawValue)")
    }

    @ViewBuilder private func BottomTabBar() -> some View {
        HStack(alignment: .center, spacing: 0) {
            TopTabButton(.spending)
            AddTabButton()
            TopTabButton(.netWorth)
        }
        .padding(.top, .paddingSmall)
        .background(chromeBackground)
        .overlay(alignment: .top) { BarDivider() }
    }

    @ViewBuilder private func TopTabButton(_ tab: TopTab) -> some View {
        let isSelected = topTab == tab
        Button {
            withAnimation(.snappy) { topTab = tab }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.sfSymbol)
                    .font(.body)
                Text(tab.label)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? chromeText : chromeMuted)
            .fontWeight(isSelected ? .semibold : .regular)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("BudgetDetailView.TabBar.\(tab.rawValue)")
    }

    /// The primary action: elevated, and context-aware — adds an account on the Net Worth tab,
    /// a recurring expense on the Recurring sub-mode, or a transaction otherwise.
    @ViewBuilder private func AddDestination() -> some View {
        if topTab == .netWorth {
            EditAccountView(budget: budget)
        } else if viewMode == .recurringExpenses {
            EditRecurringExpenseView(budget: budget)
        } else {
            EditTransactionView(budget: budget)
        }
    }

    @ViewBuilder private func AddTabButton() -> some View {
        NavigationLink {
            AddDestination()
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.heavy))
                .foregroundStyle(Color.appBackground)
                .frame(width: 52, height: 52)
                .background {
                    Circle().foregroundStyle(Color.brandTeal)
                }
                .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("BudgetDetailView.TabBar.add")
    }
    
    @ViewBuilder func FilterTransactionsButton() -> some View {
        Button {
            toggle(extraOptionsMenu: .transactionFilters)
        } label: {
            TitleBarButtonLabel(sfSymbol: "line.3.horizontal.decrease")
                .overlay(alignment: .topLeading) {
                    if transactionsFilter.count > 0 {
                        Image(systemName: "\(transactionsFilter.count).circle.fill")
                            .font(.caption2)
                            .padding(.paddingCircleButtonSmall)
                    }
                }
        }
    }
    
    @ViewBuilder func TimeFrameButton() -> some View {
        HStack(spacing: 0) {
            DecrementTimeFrameButton()
            Button {
                toggle(extraOptionsMenu: .timeFrame)
            } label: {
                Text(timeFrame.toUiString())
                    .frame(width: timeFrame.period == .week ? nil : 100)
                    .buttonLabelSmall()
                    .contentTransition(.numericText())
            }
            IncrementTimeFrameButton()
        }
    }
    
    @ViewBuilder func DecrementTimeFrameButton() -> some View {
        let isDisabled: Bool = {
            guard let _ = (budget.transactions.values.first { $0.date <= timeFrame.previous.end }) else { return true }
            return false
        }()
        
        Button {
            withAnimation(.snappy) { timeFrame = timeFrame.previous }
        } label: {
            TitleBarButtonLabel(sfSymbol: "chevron.backward")
                .opacity(isDisabled ? .opacityButtonBackground : 1)
        }
        .disabled(isDisabled)
    }
    
    @ViewBuilder func IncrementTimeFrameButton() -> some View {
        let isDisabled: Bool = {
            guard let _ = (budget.transactions.values.first { $0.date >= timeFrame.next.start }) else { return true }
            return false
        }()
        
        Button {
            withAnimation(.snappy) { timeFrame = timeFrame.next }
        } label: {
            TitleBarButtonLabel(sfSymbol: "chevron.forward")
                .opacity(isDisabled ? .opacityButtonBackground : 1)
        }
        .disabled(isDisabled)
    }
    
    @ViewBuilder func Chart() -> some View {
        Section {
            HStack {
                Spacer()
                PieChart(slices: pieSlices)
                    .valueFormatter { formatPieChart(value: $0) }
                    .containerRelativeFrame(.horizontal) { length, axis in length * 0.85 }
                Spacer()
            }
            .listRowBackground(Color.background)
            .listRowSeparator(.hidden)
            IncomeExpenseTotals()
                .padding(.bottom, .padding)
        }
        .listSectionSeparator(.hidden)
        .listSectionSpacing(0)
    }
    
    @ViewBuilder private func IncomeExpenseTotals() -> some View {
        HStack {
            IncomeTotal()
            Spacer()
            ExpensesTotal()
        }
        .listRowBackground(Color.background)
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder private func IncomeTotal() -> some View {
        let money = filteredTransactions
            .filter { $0.kind == .income }
            .reduce(into: Money.zero) { $0  = $0 + $1.amount }
        
        VStack(alignment: .leading, spacing: 2) {
            Text("Income")
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Color.text.opacity(0.5))
            Text(money.formatted())
                .foregroundStyle(money.amount > 0 ? Color.positive : Color.text)
                .contentTransition(.numericText())
        }
    }
    
    @ViewBuilder private func ExpensesTotal() -> some View {
        let money = filteredTransactions
            .filter { $0.kind == .expense }
            .reduce(into: Money.zero) { $0  = $0 + $1.amount }
        
        VStack(alignment: .trailing, spacing: 2) {
            Text("Expenses")
                .font(.caption2.bold())
                .textCase(.uppercase)
                .foregroundStyle(Color.text.opacity(0.5))
            Text(money.formatted())
                .foregroundStyle(Color.text)
                .contentTransition(.numericText())
        }
    }
    
    @ViewBuilder func TransactionList() -> some View {
        ForEach(transactionGroups) { transactionGroup in
            Section {
                let transactions = transactionGroup.transactions.sorted { budget.description(of: $0) < budget.description(of: $1) }
                ForEach(transactions) { transaction in
                    TransactionRow(transaction)
                }
            } header: {
                HStack {
                    Text(transactionGroup.date.toDate()?.toBasicUiString() ?? "Unknown Date")
                    Spacer()
                    Text(transactionGroup.formattedAmountSum(budget: budget))
                }
                .foregroundStyle(Color.text)
            }
            .listSectionSeparator(.hidden)
            .listSectionSpacing(0)
        }
        if budget.transactions.isEmpty {
            ContentUnavailableView(
                "No Transactions",
                systemImage: "dollarsign",
                description: Text("Any transactions you add will show up here")
            )
            .listRowBackground(Color.background)
            .listRowSeparator(.hidden)
        } else if transactionGroups.isEmpty {
            ContentUnavailableView(
                "No Transactions",
                systemImage: "dollarsign",
                description: Text("There are no transactions in this time period")
            )
            .listRowBackground(Color.background)
            .listRowSeparator(.hidden)
        }
    }
    
    @ViewBuilder private func TransactionRow(_ transaction: Transaction) -> some View {
        NavigationLink {
            TransactionDetailView(
                budget: budget,
                transaction: transaction
            )
        } label: {
            TransactionRowView(
                budget: budget,
                transaction: transaction,
                category: budget.getCategoryBy(id: transaction.categoryId)
            )
            .padding(.vertical, .paddingSmall)
            .padding(.leading, .paddingSmall)
            .contentShape(Rectangle())
        }
        .listRow()
    }
    
    @ViewBuilder func AdSection() -> some View {
        if subscriptionLevel == SubscriptionLevel.none {
            Section {
                NativeAdListRow(ad: $ad, size: .small)
                    .listRow()
            }
        }
    }
}

#Preview {
    NavigationStack {
        BudgetDetailView(
            budget: Budget(info: .sample),
            subscriptionManager: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}
