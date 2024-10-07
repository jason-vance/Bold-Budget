//
//  TransactionTitle.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Foundation

extension Transaction {
    struct Title {
        
        static let minTextLength: Int = 3
        static let maxTextLength: Int = 50

        let text: String
        
        init?(_ text: String) {
            // Trim whitespace
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for minimum and maximum length
            guard trimmedText.count >= Self.minTextLength, trimmedText.count <= Self.maxTextLength else {
                return nil
            }
            
            // Convert to lowercase
            self.text = trimmedText
        }
        
        static let sample: Transaction.Title = .init("Lorem ipsum dolor sit amet, consectetur adipiscing")!
    }
}
