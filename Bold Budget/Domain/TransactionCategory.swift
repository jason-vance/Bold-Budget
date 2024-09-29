//
//  TransactionCategory.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation

extension Transaction {
    struct Category: Equatable {
        let id: UUID
        let name: String
        let sfSymbol: String
    }
}

extension Transaction.Category {
    static let samples: [Transaction.Category] = [
        .init(
            id: UUID(),
            name: "Groceries",
            sfSymbol: "bag.fill"
        ),
        .init(
            id: UUID(),
            name: "Housing",
            sfSymbol: "house.fill"
        ),
        .init(
            id: UUID(),
            name: "Vehicle",
            sfSymbol: "cross.fill"
        ),
        .init(
            id: UUID(),
            name: "Entertainment",
            sfSymbol: "ticket.fill"
        ),
        .init(
            id: UUID(),
            name: "Travel",
            sfSymbol: "airplane"
        )
    ]
}
