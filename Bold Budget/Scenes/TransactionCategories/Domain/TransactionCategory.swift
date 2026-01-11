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
        
        struct Limit: Equatable, Hashable {
            let amount: Money
            let period: TimeFrame.Period
        }
        
        let id: Id
        let kind: Kind
        let name: Name
        let sfSymbol: SfSymbol
        let limit: Limit?

        init(id: Id, kind: Kind, name: Name, sfSymbol: SfSymbol, limit: Limit?) {
            self.id = id
            self.kind = kind
            self.name = name
            self.sfSymbol = sfSymbol
            self.limit = limit
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
        sfSymbol: .init("questionmark.circle.fill")!,
        limit: nil
    )
    
    static let sampleEntertainment = Transaction.Category(
        id: Id(),
        kind: .expense,
        name: .init("Entertainment")!,
        sfSymbol: .init("ticket.fill")!,
        limit: .init(amount: Money(150)!, period: .month)
    )
    static let sampleGroceries = Transaction.Category(
        id: Id(),
        kind: .expense,
        name: .init("Groceries")!,
        sfSymbol: .init("bag.fill")!,
        limit: .init(amount: Money(200)!, period: .week)
    )
    static let sampleHousing = Transaction.Category(
        id: Id(),
        kind: .expense,
        name: .init("Housing")!,
        sfSymbol: .init("house.fill")!,
        limit: .init(amount: Money(1500)!, period: .month)
    )
    static let samplePaycheck = Transaction.Category(
        id: Id(),
        kind: .income,
        name: .init("Paycheck")!,
        sfSymbol: .init("banknote.fill")!,
        limit: nil
    )
    static let sampleTravel = Transaction.Category(
        id: Id(),
        kind: .expense,
        name: .init("Travel")!,
        sfSymbol: .init("airplane")!,
        limit: .init(amount: Money(2000)!, period: .year)
    )
    static let sampleVehicle = Transaction.Category(
        id: Id(),
        kind: .expense,
        name: .init("Vehicle")!,
        sfSymbol: .init("car.side.fill")!,
        limit: .init(amount: Money(500)!, period: .month)
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
