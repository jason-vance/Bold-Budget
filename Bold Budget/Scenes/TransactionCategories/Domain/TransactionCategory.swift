//
//  TransactionCategory.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation

extension Transaction {
    struct Category {
        
        enum Kind: String, Codable {
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
        
        let id: Id
        let kind: Kind
        let name: Name
        let sfSymbol: SfSymbol
        
        init(id: Id, kind: Kind, name: Name, sfSymbol: SfSymbol) {
            self.id = id
            self.kind = kind
            self.name = name
            self.sfSymbol = sfSymbol
        }
    }
}

extension Transaction.Category {
    typealias Id = UUID
}

extension Transaction.Category: Identifiable {}

extension Transaction.Category: Equatable { }

extension Transaction.Category: Hashable { }

extension Transaction.Category {
    
    static let unknown = Transaction.Category(
        id: Id(),
        kind: .expense,
        name: .init("Unknown")!,
        sfSymbol: .init("questionmark.circle.fill")!
    )
    
    static let sampleEntertainment = Transaction.Category(
        id: Id(),
        kind: .expense,
        name: .init("Entertainment")!,
        sfSymbol: .init("ticket.fill")!
    )
    static let sampleGroceries = Transaction.Category(
        id: Id(),
        kind: .expense,
        name: .init("Groceries")!,
        sfSymbol: .init("bag.fill")!
    )
    static let sampleHousing = Transaction.Category(
        id: Id(),
        kind: .expense,
        name: .init("Housing")!,
        sfSymbol: .init("house.fill")!
    )
    static let samplePaycheck = Transaction.Category(
        id: Id(),
        kind: .income,
        name: .init("Paycheck")!,
        sfSymbol: .init("banknote.fill")!
    )
    static let sampleTravel = Transaction.Category(
        id: Id(),
        kind: .expense,
        name: .init("Travel")!,
        sfSymbol: .init("airplane")!
    )
    static let sampleVehicle = Transaction.Category(
        id: Id(),
        kind: .expense,
        name: .init("Vehicle")!,
        sfSymbol: .init("car.side.fill")!
    )
    
    static let samples: [Transaction.Category] = [
        .sampleEntertainment,
        .sampleGroceries,
        .sampleHousing,
        .samplePaycheck,
        .sampleTravel,
        .sampleVehicle,
    ]
}
