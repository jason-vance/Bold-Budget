//
//  TransactionRowView.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import SwiftUI

struct TransactionRowView: View {
    
    var transaction: Transaction
    
    var body: some View {
        HStack {
            CategoryIcon()
            TransactionText()
        }
        .foregroundStyle(Color.text)
    }
    
    @ViewBuilder func CategoryIcon() -> some View {
        Image(systemName: transaction.category.sfSymbol.value)
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
    
    @ViewBuilder func TransactionText() -> some View {
        VStack(spacing: 0) {
            Description()
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
    
    @ViewBuilder func Description() -> some View {
        HStack {
            Text(transaction.description)
                .font(.body.bold())
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(transaction.amount.formatted())
                .font(.body)
        }
    }
}

#Preview {
    TransactionRowView(transaction: .sampleRandomBasic)
        .padding(.padding)
        .background(Color.background)
}
