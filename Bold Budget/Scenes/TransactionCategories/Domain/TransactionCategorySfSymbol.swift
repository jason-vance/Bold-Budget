//
//  TransactionCategorySfSymbol.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Foundation

extension Transaction.Category {
    class SfSymbol: Equatable {
        
        static func == (lhs: SfSymbol, rhs: SfSymbol) -> Bool {
            lhs.value == rhs.value
        }
        
        let value: String
        
        init?(_ value: String?) {
            guard let value = value else { return nil }
            let trimmedText = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.contains(" ") else { return nil }
            self.value = trimmedText
        }
    }
}
