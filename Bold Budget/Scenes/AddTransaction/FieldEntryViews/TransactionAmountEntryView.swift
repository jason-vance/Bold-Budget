//
//  TransactionAmountEntryView.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/31/24.
//

import SwiftUI

struct TransactionAmountEntryView: View {
    
    @Binding var amount: Money
    var budget: Budget
    
    var body: some View {
        MoneyFieldEntryView(
            title: "Amount",
            money: $amount,
            suggestions: Array(budget.transactionAmounts)
        )
    }
}

#Preview {
    StatefulPreviewContainer(Money.zero) { amount in
        TransactionAmountEntryView(
            amount: amount,
            budget: Budget(info: .sample)
        )
    }
}
