//
//  TransactionTitleEntryView.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/29/24.
//

import SwiftUI

struct TransactionTitleEntryView: View {
    
    @Binding var titleString: String
    var budget: Budget
    
    private func titleInstructions(_ titleString: String) -> String {
        if titleString.isEmpty { return "" }
        if titleString.count < Transaction.Title.minTextLength { return "Too short" }
        if titleString.count > Transaction.Title.maxTextLength { return "Too long" }
        return "\(titleString.count)/\(Transaction.Title.maxTextLength)"
    }
    
    var body: some View {
        TextFieldEntryView(
            title: "Title",
            prompt: Transaction.Title.sample.value,
            value: $titleString,
            suggestions: budget.transactionTitles.map(\.value),
            autoCapitalization: .words,
            instructionsGenerator: { titleInstructions($0) }
        )
    }
}

#Preview {
    StatefulPreviewContainer("") { title in
        TransactionTitleEntryView(
            titleString: title,
            budget: Budget(info: .sample)
        )
    }
}
