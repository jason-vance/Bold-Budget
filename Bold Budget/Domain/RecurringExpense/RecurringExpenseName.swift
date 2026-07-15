//
//  RecurringExpenseName.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/15/26.
//

import Foundation

extension RecurringExpense {
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

        static let sample: RecurringExpense.Name = .init("Rent, Car Payment, Netflix, etc...")!
    }
}

extension RecurringExpense.Name: Identifiable {
    var id: String { value }
}

extension RecurringExpense.Name: Equatable {
    static func == (lhs: RecurringExpense.Name, rhs: RecurringExpense.Name) -> Bool {
        lhs.value == rhs.value
    }
}

extension RecurringExpense.Name: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
