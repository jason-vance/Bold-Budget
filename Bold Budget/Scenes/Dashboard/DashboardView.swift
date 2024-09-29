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
            PieChart()
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
    
    @ViewBuilder func PieChart() -> some View {
        ZStack {
            Text("Pie Chart")
                .font(.title.bold())
        }
        .frame(width: 300, height: 300)
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
