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
    
    let transactionProvider = iocContainer~>TransactionProvider.self
    
    private var transactionsPublisher: AnyPublisher<[Transaction],Never> {
        transactionProvider
            .transactionPublisher
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    @State private var transactions: [Transaction] = []
    
    @State private var showAddTransaction: Bool = false
    
    private var pieSlices: [PieChart.Slice] {
        var sliceDict = [Transaction.Category:Money]()
        
        for transaction in transactions {
            sliceDict[transaction.category] = sliceDict[transaction.category, default: .zero] + transaction.amount
        }
        
        return sliceDict.map { key, value in
            PieChart.Slice(name: key.name, value: value.amount)
        }
    }
    
    var body: some View {
        VStack {
            List {
                Chart()
                TransactionList()
            }
            .listStyle(.plain)
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
    
    @ViewBuilder func AddTransactionButton() -> some View {
        Button {
            showAddTransaction = true
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(Color.background)
                .font(.title)
                .padding()
                .background {
                    Circle()
                        .foregroundStyle(Color.text)
                }
        }
        .padding()
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
        ForEach(transactions) { transaction in
            TransactionRowView(transaction)
                .listRowBackground(Color.background)
                .listRowSeparatorTint(Color.text)
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
