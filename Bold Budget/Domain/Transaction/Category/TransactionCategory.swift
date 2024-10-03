//
//  TransactionCategory.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation

extension Transaction {
    struct Category: Equatable, Hashable, Identifiable {
        
        enum Kind: Codable {
            case expense
            case income
            
            var name: String {
                switch self {
                case .expense:
                    String(localized: "Expense")
                case .income:
                    String(localized: "Income")
                }
            }
        }
        
        var id: String { name.value }
        let kind: Kind
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
            kind: .expense,
            name: .init("Groceries")!,
            sfSymbol: .init("bag.fill")!
        ),
        .init(
            kind: .expense,
            name: .init("Housing")!,
            sfSymbol: .init("house.fill")!
        ),
        .init(
            kind: .expense,
            name: .init("Vehicle")!,
            sfSymbol: .init("cross.fill")!
        ),
        .init(
            kind: .expense,
            name: .init("Entertainment")!,
            sfSymbol: .init("ticket.fill")!
        ),
        .init(
            kind: .expense,
            name: .init("Travel")!,
            sfSymbol: .init("airplane")!
        )
    ]
}
