//
//  DashboardView.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import SwiftUI
import SwinjectAutoregistration
import Combine

struct DashboardView: View {
    
    private enum ExtraOptionsMenu {
        case timeFrame
        case transactionFilters
    }
    
    struct TransactionGroup: Identifiable {
        var id: SimpleDate { date }
        let date: SimpleDate
        var transactions: [Transaction]
    }
    
    //TODO: Put this into the constructor
    let transactionProvider = iocContainer~>TransactionProvider.self
    private var transactionsPublisher: AnyPublisher<[Transaction],Never> {
        transactionProvider
            .transactionPublisher
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    private let __budget: Budget
    
    @State private var currentUserData: UserData? = nil
    @State private var budget: Budget? = nil
    @State private var transactions: [Transaction] = []
    @State private var timeFrame: TimeFrame = .init(period: .month, containing: .now)
    @State private var transactionsFilter: TransactionsFilter = .none
    
    @State private var showTimeFramePicker: Bool = false
    @State private var showFilterTransactionsOptions: Bool = false
    
    private let currentUserIdProvider: CurrentUserIdProvider
    private let currentUserDataProvider: CurrentUserDataProvider
    
    init(budget: Budget) {
        self.init(
            budget: budget,
            currentUserIdProvider: iocContainer~>CurrentUserIdProvider.self,
            currentUserDataProvider: iocContainer~>CurrentUserDataProvider.self
        )
    }
    
    init(
        budget: Budget,
        currentUserIdProvider: CurrentUserIdProvider,
        currentUserDataProvider: CurrentUserDataProvider
    ) {
        self.__budget = budget
        self.currentUserIdProvider = currentUserIdProvider
        self.currentUserDataProvider = currentUserDataProvider
    }
    
    private var currentUserId: UserId? { currentUserIdProvider.currentUserId }

    private var filteredTransactions: [Transaction] {
        transactions
            .filter {
                $0.date >= timeFrame.start &&
                $0.date <= timeFrame.end &&
                transactionsFilter.shouldInclude($0)
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
        var sliceDict = [Transaction.Category:Money]()
        
        for transaction in filteredTransactions {
            sliceDict[transaction.category] = sliceDict[transaction.category, default: .zero] + transaction.amount
        }
        
        return sliceDict.map { key, value in
            PieChart.Slice(value: value.amount, category: key)
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
    
    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            List {
                Chart()
                TransactionList()
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom, alignment: .trailing) { AddTransactionButton() }
            .overlay(alignment: .top) {
                Rectangle()
                    .opacity(0)
                    .overlay(alignment: .top) { ExtraOptionsMenuOverlay() }
                    .clipped()
            }
        }
        .navigationTitle(budget?.name.value ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .foregroundStyle(Color.text)
        .background(Color.background)
        .onChange(of: __budget, initial: true) { _, budget in self.budget = budget }
        .onReceive(transactionsPublisher) { transactions = $0 }
        .onReceive(currentUserDataProvider.currentUserDataPublisher) { currentUserData = $0 }
    }
    
    @ViewBuilder private func NewBudgetDialogSheet() -> some View {
        AddBudgetView()
            .presentationBackground(Color.background)
            .presentationDragIndicator(.visible)
            .presentationDetents([.large])
    }
    
    @ViewBuilder private func ExtraOptionsMenuOverlay() -> some View {
        if showExtraOptionsMenu {
            VStack(spacing: 0) {
                if showFilterTransactionsOptions {
                    //TODO: Turn this into a sheet
                    TransactionsFilterMenu(
                        isMenuVisible: $showFilterTransactionsOptions,
                        transactionsFilter: $transactionsFilter,
                        transactionCount: .init(get: { filteredTransactions.count }, set: {_ in})
                    )
                } else if showTimeFramePicker {
                    //TODO: Turn this into a sheet
                    TimeFramePicker(timeFrame: .init(
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
            primaryContent: { TimeFrameButton() },
            leadingContent: { FilterTransactionsButton().opacity(0) },
            trailingContent: { FilterTransactionsButton() }
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
        .accessibilityIdentifier("DashboardView.FilterTransactionsButton")
    }
    
    @ViewBuilder func TimeFrameButton() -> some View {
        HStack(spacing: 0) {
            DecrementTimeFrameButton()
            Button {
                toggle(extraOptionsMenu: .timeFrame)
            } label: {
                Text(timeFrame.toUiString())
                    .frame(width: 100)
                    .buttonLabelSmall()
                    .contentTransition(.numericText())
            }
            IncrementTimeFrameButton()
        }
    }
    
    @ViewBuilder func DecrementTimeFrameButton() -> some View {
        let isDisabled: Bool = {
            guard let _ = (transactions.first { $0.date <= timeFrame.previous.end }) else { return true }
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
            guard let _ = (transactions.first { $0.date >= timeFrame.next.start }) else { return true }
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
            AddTransactionView()
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
                Spacer(minLength: 0)
                PieChart(slices: pieSlices)
                    .valueFormatter { formatPieChart(value: $0) }
                    .containerRelativeFrame(.horizontal) { length, axis in length * 0.85 }
                Spacer(minLength: 0)
            }
            .listRowBackground(Color.background)
            .listRowSeparator(.hidden)
        } header: {
            ZStack{}
        }
        .listSectionSeparator(.hidden)
        .listSectionSpacing(0)
    }
    
    @ViewBuilder func TransactionList() -> some View {
        ForEach(transactionGroups) { transactionGroup in
            Section {
                let transactions = transactionGroup.transactions.sorted { $0.description < $1.description }
                ForEach(transactions) { transaction in
                    TransactionRow(transaction)
                }
            } header: {
                Text(transactionGroup.date.toDate()?.toBasicUiString() ?? "Unknown Date")
                    .foregroundStyle(Color.text)
            }
            .listSectionSeparator(.hidden)
            .listSectionSpacing(0)
        }
        if transactions.isEmpty {
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
            TransactionDetailView(transaction: transaction)
        } label: {
            TransactionRowView(transaction)
        }
        .dashboardTransactionRow()
    }
}

#Preview {
    NavigationStack {
        DashboardView(
            budget: .sample,
            currentUserIdProvider: MockCurrentUserIdProvider(currentUserId: .sample),
            currentUserDataProvider: MockCurrentUserDataProvider()
        )
    }
}
