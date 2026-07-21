//
//  FirebaseTransactionCategoryDoc.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/25/24.
//

import Foundation
import FirebaseFirestore

struct FirebaseTransactionCategoryDoc: Codable {
    
    @DocumentID var id: String?
    var kind: String?
    var name: String?
    var sfSymbol: String?
    var limitAmount: Double?
    var limitPeriod: String?

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case name
        case sfSymbol
        case limitAmount
        case limitPeriod
    }
    
    static func from(_ category: Transaction.Category) -> FirebaseTransactionCategoryDoc {
        // `kind` is no longer part of a category; existing docs keep their stored value (read only
        // by the one-time transaction-kind backfill) and new docs simply omit it.
        FirebaseTransactionCategoryDoc(
            id: category.id.uuidString,
            kind: nil,
            name: category.name.value,
            sfSymbol: category.sfSymbol.value,
            limitAmount: category.limit?.amount.amount,
            limitPeriod: category.limit?.period.rawValue
        )
    }

    func toCategory() -> Transaction.Category? {
        guard let id = Transaction.Category.Id(uuidString: id ?? "") else { return nil }
        guard let name = Transaction.Category.Name(name) else { return nil }
        guard let sfSymbol = Transaction.Category.SfSymbol(sfSymbol) else { return nil }

        let limit: Transaction.Category.Limit? = {
            guard let amount = Money(limitAmount), let period = TimeFrame.Period(rawValue: limitPeriod ?? "") else {
                return nil
            }
            return .init(amount: amount, period: period)
        }()

        return .init(
            id: id,
            name: name,
            sfSymbol: sfSymbol,
            limit: limit
        )
    }

    /// The legacy income/expense kind stored on this document, if any, for one-time migration.
    func legacyKind() -> Transaction.Kind? {
        switch kind {
        case "income": return .income
        case "expense": return .expense
        default: return nil
        }
    }
}
