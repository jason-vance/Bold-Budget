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
    var showsDate: Bool = true

    var body: some View {
        HStack(spacing: .padding) {
            IconCircle(systemName: iconSymbol, size: 40, tint: .brandTeal)
            VStack(alignment: .leading, spacing: 2) {
                Text(budget.description(of: transaction))
                    .font(.body.bold())
                    .lineLimit(1)
                SubtitleLine()
            }
            Spacer(minLength: 0)
            Text(budget.amountString(for: transaction))
                .font(.body.weight(.semibold))
                .foregroundStyle(amountColor)
        }
        .foregroundStyle(Color.appText)
    }

    private var iconSymbol: String {
        transaction.isTransfer ? "arrow.left.arrow.right" : category.sfSymbol.value
    }
    
    /// The transfer route ("Checking → Savings") or the linked account name, if any.
    private var accountChip: String? {
        budget.transferRouteDescription(for: transaction) ?? budget.accountName(for: transaction)
    }
    
    private var accountChipSymbol: String {
        transaction.isTransfer ? "arrow.left.arrow.right" : budget.accountSymbol(for: transaction) ?? "building.columns"
    }

    @ViewBuilder private func SubtitleLine() -> some View {
        HStack(spacing: .paddingSmall) {
            if let location = transaction.location?.value {
                Text(location)
                    .font(.caption.weight(.light))
                    .lineLimit(1)
                    .foregroundStyle(Color.appMutedText)
            }
            if let accountChip {
                Chip(text: accountChip, systemName: accountChipSymbol)
            }
            if showsDate {
                Text(transaction.date.toDate()?.toBasicUiString() ?? "")
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(Color.appMutedText)
            }
        }
    }

    private var amountColor: Color {
        if transaction.isTransfer { return Color.appText.opacity(.opacityMutedText) }
        return transaction.kind == .income ? Color.positive : Color.appText
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
