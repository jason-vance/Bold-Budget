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
    
    struct TransactionGroup: Identifiable {
        var id: SimpleDate { date }
        let date: SimpleDate
        var transactions: [Transaction]
    }
    
    let transactionProvider = iocContainer~>TransactionProvider.self
    
    private var transactionsPublisher: AnyPublisher<[Transaction],Never> {
        transactionProvider
            .transactionPublisher
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    @State private var transactions: [Transaction] = []
    private var transactionGroups: [TransactionGroup] {
        let dict = transactions.reduce(Dictionary<SimpleDate,[Transaction]>()) { dict, transaction in
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
    
    @State private var showAddTransaction: Bool = false
    
    private var pieSlices: [PieChart.Slice] {
        var sliceDict = [Transaction.Category:Money]()
        
        for transaction in transactions {
            sliceDict[transaction.category] = sliceDict[transaction.category, default: .zero] + transaction.amount
        }
        
        return sliceDict.map { key, value in
            PieChart.Slice(name: key.name.value, value: value.amount)
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
            .listRowSpacing(0)
        }
        .overlay(alignment: .bottomTrailing) {
            AddTransactionButton()
        }
        .foregroundStyle(Color.text)
        .background(Color.background)
        .onReceive(transactionsPublisher) { transactions = $0 }
        .fullScreenCover(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
    }
    
    @ViewBuilder func TopBar() -> some View {
        ScreenTitleBar(
            primaryContent: { Text("Dashboard") },
            leadingContent: { TimeFrameButton() },
            trailingContent: { AddTransactionButton() }
        )
    }
    
    @ViewBuilder func TimeFrameButton() -> some View {
        Button {
            //showTimeFramePicker = true
        } label: {
            TitleBarButtonLabel(sfSymbol: "calendar")
        }
    }
    
    @ViewBuilder func AddTransactionButton() -> some View {
        Button {
            showAddTransaction = true
        } label: {
            TitleBarButtonLabel(sfSymbol: "plus")
        }
    }
    
    @ViewBuilder func Chart() -> some View {
        HStack {
            Spacer(minLength: 0)
            PieChart(slices: pieSlices)
                .color(Color.text)
                .valueFormatter { value in Money(value)?.formatted() ?? value.formatted() }
                .containerRelativeFrame(.horizontal) { length, axis in length * 0.75 }
            Spacer(minLength: 0)
        }
        .padding(.bottom, 32)
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color.text)
        }
        .listRowBackground(Color.background)
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder func TransactionList() -> some View {
        ForEach(transactionGroups) { transactionGroup in
            Section {
                let transactions = transactionGroup.transactions.sorted { $0.description < $1.description }
                ForEach(transactions) { transaction in
                    TransactionRowView(transaction)
                        .dashboardTransactionRow()
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
        }
    }
}

#Preview {
    DashboardView()
}
