//
//  TransactionTagView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/9/24.
//

import SwiftUI

struct TransactionTagView: View {
    
    public let tag: Transaction.Tag
    
    init(_ tag: Transaction.Tag) {
        self.tag = tag
    }
    
    var body: some View {
        HStack(spacing: .paddingHorizontalButtonXSmall) {
            Image(systemName: "tag")
                .foregroundStyle(Color.text)
                .frame(height: 24)
            Text(tag.value)
                .foregroundStyle(Color.text)
        }
        .font(.caption)
        .padding(.horizontal, .paddingHorizontalButtonXSmall)
        .background {
            RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                .foregroundStyle(Color.text.opacity(.opacityButtonBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous))
    }
}

#Preview {
    VStack {
        ForEach(Transaction.Tag.samples) { tag in
            TransactionTagView(tag)
        }
    }
}
