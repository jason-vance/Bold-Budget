//
//  TransactionLocation.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Foundation

extension Transaction {
    struct Location {
        
        static let minTextLength: Int = 3
        static let maxTextLength: Int = 100

        let value: String
        
        init?(_ value: String) {
            // Trim whitespace
            let trimmedText = value.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for minimum and maximum length
            guard trimmedText.count >= Self.minTextLength, trimmedText.count <= Self.maxTextLength else {
                return nil
            }
            
            // Starts and ends with a letter
            guard let first = trimmedText.first, let last = trimmedText.last else { return nil }
            guard first.isLetter, last.isLetter else { return nil }
            
            // Convert to lowercase
            self.value = trimmedText
        }
        
        static let sample: Transaction.Location = .init("Cupertino, CA")!
    }
}
