//
//  TransactionCategory.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation

extension Transaction {
    struct Category: Equatable, Hashable {
        let id: UUID
        let name: Name
        let sfSymbol: SfSymbol
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

extension Transaction.Category {
    static let samples: [Transaction.Category] = [
        .init(
            id: UUID(),
            name: .init("Groceries")!,
            sfSymbol: .init("bag.fill")!
        ),
        .init(
            id: UUID(),
            name: .init("Housing")!,
            sfSymbol: .init("house.fill")!
        ),
        .init(
            id: UUID(),
            name: .init("Vehicle")!,
            sfSymbol: .init("cross.fill")!
        ),
        .init(
            id: UUID(),
            name: .init("Entertainment")!,
            sfSymbol: .init("ticket.fill")!
        ),
        .init(
            id: UUID(),
            name: .init("Travel")!,
            sfSymbol: .init("airplane")!
        )
    ]
}
