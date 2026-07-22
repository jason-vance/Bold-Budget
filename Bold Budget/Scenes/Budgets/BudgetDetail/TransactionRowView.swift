//
//  TransactionRowView.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import SwiftUI

struct TransactionRowView: View {
    
    var budget: Budget
    var transaction: Transaction
    var category: Transaction.Category
    
    var body: some View {
        HStack(spacing: .padding) {
            IconCircle(systemName: iconSymbol, size: 44)
            TransactionText()
        }
        .foregroundStyle(Color.text)
    }

    private var iconSymbol: String {
        transaction.isTransfer ? "arrow.left.arrow.right" : category.sfSymbol.value
    }

    /// The transfer route ("Checking → Savings") or the linked account name, if any.
    private var accountChip: String? {
        budget.transferRouteDescription(for: transaction) ?? budget.accountName(for: transaction)
    }

    @ViewBuilder func TransactionText() -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Description()
            HStack(spacing: .paddingSmall) {
                if let accountChip {
                    Chip(text: accountChip, systemName: transaction.isTransfer ? "arrow.left.arrow.right" : "building.columns")
                }
                if let location = transaction.location?.value {
                    Text(location)
                        .font(.caption.weight(.light))
                        .lineLimit(1)
                        .foregroundStyle(Color.text.opacity(.opacityMutedText))
                }
                Spacer(minLength: 0)
                Text(transaction.date.toDate()?.toBasicUiString() ?? "")
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(Color.text.opacity(0.5))
            }
        }
    }

    private var amountColor: Color {
        if transaction.isTransfer { return Color.text.opacity(.opacityMutedText) }
        return transaction.kind == .income ? Color.positive : Color.text
    }

    @ViewBuilder func Description() -> some View {
        HStack {
            Text(budget.description(of: transaction))
                .font(.body.bold())
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(budget.amountString(for: transaction))
                .font(.body.weight(.semibold))
                .foregroundStyle(amountColor)
        }
    }
}

#Preview {
    List {
        ForEach(Transaction.screenshotSamples) { transaction in
            TransactionRowView(
                budget: .init(info: .sample),
                transaction: transaction,
                category: .unknown
            )
            .listRowNoChrome()
        }
    }
    .listStyle(.insetGrouped)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
}
