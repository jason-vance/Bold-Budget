//
//  TransactionCategorySfSymbol.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Foundation

extension Transaction.Category {
    class SfSymbol {
        
        let value: String
        
        init?(_ value: String?) {
            guard let value = value else { return nil }
            let trimmedText = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.contains(" ") else { return nil }
            self.value = trimmedText
        }
    }
}

extension Transaction.Category.SfSymbol: Equatable {
    static func == (lhs: Transaction.Category.SfSymbol, rhs: Transaction.Category.SfSymbol) -> Bool {
        lhs.value == rhs.value
    }
}

extension Transaction.Category.SfSymbol: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

