//
//  DashboardView.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import SwiftUI

struct DashboardView: View {
    
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
    }
    
    @ViewBuilder func PieChart() -> some View {
        ZStack {
            Text("Pie Chart")
                .font(.title.bold())
        }
        .frame(width: 300, height: 300)
    }
    
    @ViewBuilder func TransactionList() -> some View {
        //TODO: Get real transactions
        ForEach(1...10, id: \.self) { index in
            TransactionRowView(.sampleBasic)
                .listRowBackground(Color.background)
                .listRowSeparatorTint(Color.text)
        }
    }
}

#Preview {
    DashboardView()
}
