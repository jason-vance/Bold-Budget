//
//  TransactionCategory.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation

extension Transaction {
    struct Category: Equatable, Hashable, Identifiable {
        var id: String { name.value }
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
            name: .init("Groceries")!,
            sfSymbol: .init("bag.fill")!
        ),
        .init(
            name: .init("Housing")!,
            sfSymbol: .init("house.fill")!
        ),
        .init(
            name: .init("Vehicle")!,
            sfSymbol: .init("cross.fill")!
        ),
        .init(
            name: .init("Entertainment")!,
            sfSymbol: .init("ticket.fill")!
        ),
        .init(
            name: .init("Travel")!,
            sfSymbol: .init("airplane")!
        )
    ]
}
