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
                let category = budget.getCategoryBy(id: $1.categoryId)
                let sign = (category.kind == .income) ? 1.0 : -1.0
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
    @AppStorage("previousTimeFramePeriod") private var previousTimeFramePeriod: TimeFrame.Period = .month
    @AppStorage("previousTimeFrameDate") private var previousTimeFrameDate: Int = Int(SimpleDate.now.rawValue)

    @StateObject var budget: Budget
    
    @State private var currentUserData: UserData? = nil
    @State private var timeFrame: TimeFrame = .init(period: .month, containing: .now) {
        didSet {
            previousTimeFramePeriod = timeFrame.period
            previousTimeFrameDate = Int(timeFrame.start.rawValue)
        }
    }
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
        var sliceDict = [Transaction.Category.Id:Money]()
        
        for transaction in filteredTransactions {
            sliceDict[transaction.categoryId] = sliceDict[transaction.categoryId, default: .zero] + transaction.amount
        }
        
        return sliceDict.map { key, value in
            PieChart.Slice(
                value: value.amount,
                category: budget.getCategoryBy(id: key)
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
            TopBar()
            List {
                Chart()
                AdSection()
                TransactionList()
            }
            .refreshable { budget.refresh() }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .overlay(alignment: .bottomTrailing) { AddTransactionButton() }
            .overlay(alignment: .top) {
                Rectangle()
                    .opacity(0)
                    .overlay(alignment: .top) { ExtraOptionsMenuOverlay() }
                    .clipped()
            }
            .overlay {
                if budget.isLoading {
                    BlockingSpinnerView()
                }
            }
        }
        .navigationTitle(budget.info.name.value)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Toolbar() }
        .foregroundStyle(Color.text)
        .background(Color.background)
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .alert(alertMessage, isPresented: $showAlert) {}
        .animation(.snappy, value: budget.isLoading)
        .onAppear { promptForReview() }
        .onAppear { timeFrame = .init(period: previousTimeFramePeriod, containing: SimpleDate(rawValue: SimpleDate.RawValue(previousTimeFrameDate))!) }
        .onReceive(subscriptionManager.subscriptionLevelPublisher) { subscriptionLevel = $0 }
        .onChange(of: scenePhase) { old, new in onChangeOf(scenePhase: new) }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
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
        ScreenTitleBar(
            primaryContent: {
                TimeFrameButton()
            },
            leadingContent: {
                FilterTransactionsButton().opacity(0)
            },
            trailingContent: {
                FilterTransactionsButton()
                    .accessibilityIdentifier("DashboardView.FilterTransactionsButton")
            }
        )
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
    
    @ViewBuilder func AddTransactionButton() -> some View {
        NavigationLink {
            EditTransactionView(budget: budget)
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
        .accessibilityIdentifier("DashboardView.AddTransactionButton")
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
            HStack {
                IncomeTotal()
                Spacer()
                ExpensesTotal()
            }
            .padding(.bottom, .padding)
            .listRowBackground(Color.background)
            .listRowSeparator(.hidden)
        }
        .listSectionSeparator(.hidden)
        .listSectionSpacing(0)
    }
    
    @ViewBuilder private func IncomeTotal() -> some View {
        let money = filteredTransactions
            .filter( { budget.getCategoryBy(id: $0.categoryId).kind == .income })
            .reduce(into: Money.zero) { $0  = $0 + $1.amount }
        
        VStack(alignment: .leading, spacing: 2) {
            Text("Income")
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Color.text.opacity(0.5))
            Text(money.formatted())
                .foregroundStyle(Color.text)
                .contentTransition(.numericText())
        }
    }
    
    @ViewBuilder private func ExpensesTotal() -> some View {
        let money = filteredTransactions
            .filter( { budget.getCategoryBy(id: $0.categoryId).kind == .expense })
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
}
