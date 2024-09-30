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
            Chart()
            List {
                TransactionList()
            }
            .listStyle(.plain)
            .scrollIndicators(.hidden)
            .listRowSpacing(0)
        }
        .foregroundStyle(Color.text)
        .background(Color.background)
        .onReceive(transactionsPublisher) { transactions = $0 }
    }
    
    @ViewBuilder func Chart() -> some View {
        PieChart(slices: pieSlices)
            .color(Color.text)
            .valueFormatter { value in Money(value)?.formatted() ?? value.formatted() }
            .containerRelativeFrame(.horizontal) { length, axis in length * 0.75 }
    }
    
    @ViewBuilder func TransactionList() -> some View {
        ForEach(transactions) { transaction in
            TransactionRowView(transaction)
                .listRowBackground(Color.background)
                .listRowSeparatorTint(Color.text)
        }
        //TODO: Show something if there are no transactions
    }
}

#Preview {
    DashboardView()
}
