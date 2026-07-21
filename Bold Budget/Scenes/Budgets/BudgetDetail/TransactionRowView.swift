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
            CategoryIcon()
            TransactionText()
        }
        .foregroundStyle(Color.text)
    }
    
    private var iconSymbol: String {
        transaction.isTransfer ? "arrow.left.arrow.right" : category.sfSymbol.value
    }

    @ViewBuilder func CategoryIcon() -> some View {
        Image(systemName: iconSymbol)
            .padding(.padding)
            .frame(width: 48, height: 48)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .stroke(style: .init(lineWidth: .borderWidthThin))
                    .foregroundStyle(Color.text)
            }
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .foregroundStyle(Color.text.opacity(.opacityButtonBackground))
            }
    }
    
    /// The transfer route ("Checking → Savings") or the linked account name, if any.
    private var accountLine: String? {
        budget.transferRouteDescription(for: transaction) ?? budget.accountName(for: transaction)
    }

    @ViewBuilder func TransactionText() -> some View {
        VStack(spacing: 0) {
            Description()
            if let accountLine {
                HStack {
                    Image(systemName: "building.columns")
                        .font(.caption2)
                    Text(accountLine)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .opacity(0.7)
            }
            HStack {
                Text(transaction.location?.value ?? "Unknown Location")
                    .font(.caption.weight(.light))
                    .lineLimit(1)
                    .opacity(transaction.location == nil ? 0 : 1)
                Spacer(minLength: 0)
            }
            HStack {
                Text(transaction.date.toDate()?.toBasicUiString() ?? "Unkown Date")
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .opacity(transaction.date.toDate() == nil ? 0 : 0.5)
                Spacer(minLength: 0)
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
                .font(.body)
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
