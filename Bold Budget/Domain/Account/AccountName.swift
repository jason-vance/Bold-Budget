//
//  AccountName.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/21/26.
//

import Foundation

extension Account {
    class Name {

        static let minTextLength: Int = 1
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

            self.value = trimmedText
        }

        static let sample: Account.Name = .init("Checking, Robinhood, Car Loan, etc...")!
    }
}

extension Account.Name: Identifiable {
    var id: String { value }
}

extension Account.Name: Equatable {
    static func == (lhs: Account.Name, rhs: Account.Name) -> Bool {
        lhs.value == rhs.value
    }
}

extension Account.Name: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
