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
        
        let id: UUID
        let kind: Kind
        let name: Name
        let sfSymbol: SfSymbol
                
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

extension Transaction.Category {
    
    static let sampleEntertainment = Transaction.Category(
        id: UUID(),
        kind: .expense,
        name: .init("Entertainment")!,
        sfSymbol: .init("ticket.fill")!
    )
    static let sampleGroceries = Transaction.Category(
        id: UUID(),
        kind: .expense,
        name: .init("Groceries")!,
        sfSymbol: .init("bag.fill")!
    )
    static let sampleHousing = Transaction.Category(
        id: UUID(),
        kind: .expense,
        name: .init("Housing")!,
        sfSymbol: .init("house.fill")!
    )
    static let samplePaycheck = Transaction.Category(
        id: UUID(),
        kind: .income,
        name: .init("Paycheck")!,
        sfSymbol: .init("banknote.fill")!
    )
    static let sampleTravel = Transaction.Category(
        id: UUID(),
        kind: .expense,
        name: .init("Travel")!,
        sfSymbol: .init("airplane")!
    )
    static let sampleVehicle = Transaction.Category(
        id: UUID(),
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
