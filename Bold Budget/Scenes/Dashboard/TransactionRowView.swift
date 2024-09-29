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
        //TODO: Get real category image
        Image(systemName: "bag.fill")
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
                //TODO: Remove default text
                Text(transaction.location ?? "Mililani, HI")
                    .font(.callout.weight(.light))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            HStack {
                Text(transaction.date.toBasicUiString())
                    .font(.footnote.weight(.light))
                    .lineLimit(1)
                    .opacity(0.75)
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
    TransactionRowView(.sampleBasic)
        .padding(.padding)
        .background(Color.background)
}
