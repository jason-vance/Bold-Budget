//
//  TransactionRowView.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import SwiftUI

struct TransactionRowView: View {
    
    @State private var transaction: Transaction
    
    init(_ transaction: Transaction) {
        self.transaction = transaction
    }
    
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
            .frame(width: 44, height: 44)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .stroke(style: .init(lineWidth: .borderWidthMedium))
                    .foregroundStyle(Color.text)
            }
    }
    
    @ViewBuilder func TransactionText() -> some View {
        VStack {
            Description()
            HStack {
                Text(transaction.location ?? "Unknown Location")
                    .font(.callout.weight(.light))
                    .lineLimit(1)
                    .opacity(transaction.location == nil ? 0 : 1)
                Spacer(minLength: 0)
            }
            HStack {
                Text(transaction.date.toDate()?.toBasicUiString() ?? "Unkown Date")
                    .font(.footnote.weight(.light))
                    .lineLimit(1)
                    .opacity(transaction.date.toDate() == nil ? 0 : 0.75)
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
    TransactionRowView(.sampleRandomBasic)
        .padding(.padding)
        .background(Color.background)
}
