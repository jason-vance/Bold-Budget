//
//  TransactionLocation.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Foundation

extension Transaction {
    class Location {
        
        static let minTextLength: Int = 3
        static let maxTextLength: Int = 100

        let value: String
        
        init?(_ value: String?) {
            guard let value = value else { return nil }
            
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

extension Transaction.Location: Equatable {
    static func == (lhs: Transaction.Location, rhs: Transaction.Location) -> Bool {
        lhs.value == rhs.value
    }
}

extension Transaction.Location: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
