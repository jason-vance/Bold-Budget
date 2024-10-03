//
//  TransactionCategorySfSymbol.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Foundation

extension Transaction.Category {
    struct SfSymbol: Equatable {
        
        let value: String
        
        init?(_ value: String) {
            let trimmedText = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.contains(" ") else { return nil }
            self.value = trimmedText
        }
    }
}
