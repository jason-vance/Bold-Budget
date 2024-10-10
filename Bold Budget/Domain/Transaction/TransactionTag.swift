//
//  TransactionTag.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/9/24.
//

import Foundation

extension Transaction {
    struct Tag {
        
        static let minTextLength: Int = 2
        static let maxTextLength: Int = 32

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
    }
}

extension Transaction.Tag: Codable {}

extension Transaction.Tag: Identifiable {
    var id: String { value }
}

extension Transaction.Tag {
    
    static let sample: Transaction.Tag = .init("Beach Trip")!
    
    static let samples: [Transaction.Tag] = [
        .init("Big Island Trip")!,
        .init("With Parents")!,
        .init("Some Other Tag")!
    ]
}
