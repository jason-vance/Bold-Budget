//
//  TransactionCategoryName.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Foundation

extension Transaction.Category {
    class Name {
        
        static let minTextLength: Int = 3
        static let maxTextLength: Int = 20
        
        let value: String
        
        init?(_ value: String?) {
            guard let value = value else { return nil }
            
            // Trim whitespace
            let trimmedText = value.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for minimum and maximum length
            guard trimmedText.count >= Self.minTextLength, trimmedText.count <= Self.maxTextLength else {
                return nil
            }
            
            // Convert to lowercase
            self.value = trimmedText
        }
        
        static let sample: Transaction.Category.Name = .init("Groceries")!
    }
}

extension Transaction.Category.Name: Equatable {
    static func == (lhs: Transaction.Category.Name, rhs: Transaction.Category.Name) -> Bool {
        lhs.value == rhs.value
    }
}

extension Transaction.Category.Name: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
