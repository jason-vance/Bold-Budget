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
        HStack(spacing: 0) {
            Image(systemName: "tag")
                .frame(width: 24, height: 24)
                .background(Color.text.opacity(.opacityButtonBackground))
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .frame(width: .borderWidthThin)
                        .foregroundStyle(Color.text)
                        .offset(x: .borderWidthThin)
                }
            Text(tag.value)
                .padding(.horizontal, .padding)
        }
        .font(.caption)
        .foregroundStyle(Color.text)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                .stroke(style: .init(lineWidth: .borderWidthThin))
                .foregroundStyle(Color.text)
        }
    }
}

#Preview {
    VStack {
        ForEach(Transaction.Tag.samples) { tag in
            TransactionTagView(tag)
        }
    }
}
