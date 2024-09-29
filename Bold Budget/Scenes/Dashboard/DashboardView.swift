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
        PieChart(slices: PieChart.Slice.samples)
            .color(Color.text)
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
