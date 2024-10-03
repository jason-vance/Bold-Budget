//
//  TransactionCategoryName.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Foundation

extension Transaction.Category {
    struct Name: Equatable {
        
        static let minTextLength: Int = 3
        static let maxTextLength: Int = 20
        
        let value: String
        
        init?(_ value: String) {
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
