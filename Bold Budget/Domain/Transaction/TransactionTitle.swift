//
//  TransactionTitle.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Foundation

extension Transaction {
    class Title {
        
        static let minTextLength: Int = 3
        static let maxTextLength: Int = 50

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
        
        static let sample: Transaction.Title = .init("Milk Tea, Movie Tickets, etc...")!
    }
}

extension Transaction.Title: Identifiable {
    var id: String { value }
}

extension Transaction.Title: Equatable {
    static func == (lhs: Transaction.Title, rhs: Transaction.Title) -> Bool {
        lhs.value == rhs.value
    }
}

extension Transaction.Title: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
