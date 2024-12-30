//
//  TransactionLocationEntryView.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/29/24.
//

import SwiftUI

struct TransactionLocationEntryView: View {
    
    @Binding var locationString: String
    
    private func locationInstructions(_ locationString: String) -> String {
        if locationString.isEmpty { return "" }
        if locationString.count < Transaction.Location.minTextLength { return "Too short" }
        if locationString.count > Transaction.Location.maxTextLength { return "Too long" }
        return "\(locationString.count)/\(Transaction.Location.maxTextLength)"
    }
    
    var body: some View {
        TextFieldEntryView(
            title: "Location",
            prompt: Transaction.Location.sample.value,
            value: $locationString,
            autoCapitalization: .words,
            instructionsGenerator: { locationInstructions($0) }
        )
    }
}

#Preview {
    StatefulPreviewContainer("") { location in
        TransactionLocationEntryView(locationString: location)
    }
}
