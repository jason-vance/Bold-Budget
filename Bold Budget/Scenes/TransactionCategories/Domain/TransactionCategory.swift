//
//  TransactionCategory.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation

extension Transaction {
    struct Category {

        struct Goal: Equatable, Hashable {

            /// Whether spending should stay under the target or reach at least it.
            enum Comparison: String, Codable, CaseIterable {
                case lessThan
                case greaterThan

                var name: String {
                    switch self {
                    case .lessThan: String(localized: "Less than")
                    case .greaterThan: String(localized: "Greater than")
                    }
                }
            }

            let amount: Money
            let period: TimeFrame.Period
            let comparison: Comparison

            init(amount: Money, period: TimeFrame.Period, comparison: Comparison = .lessThan) {
                self.amount = amount
                self.period = period
                self.comparison = comparison
            }
        }

        let id: Id
        let name: Name
        let sfSymbol: SfSymbol
        let goal: Goal?

        init(id: Id, name: Name, sfSymbol: SfSymbol, goal: Goal?) {
            self.id = id
            self.name = name
            self.sfSymbol = sfSymbol
            self.goal = goal
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

    /// A fixed, persistable id used as the `categoryId` of transfers, which have no real
    /// spending category. Resolves to `.unknown` via `getCategoryBy(id:)`; transfer rows are
    /// rendered specially and excluded from spending totals, so its kind is never used.
    static let transferId = Transaction.Category.Id(uuidString: "00000000-0000-0000-0000-000000000000")!

    static let unknown = Transaction.Category(
        id: Id(),
        name: .init("Unknown")!,
        sfSymbol: .init("questionmark.circle.fill")!,
        goal: nil
    )
    
    static let sampleEntertainment = Transaction.Category(
        id: Id(),
        name: .init("Entertainment")!,
        sfSymbol: .init("ticket.fill")!,
        goal: .init(amount: Money(150)!, period: .month)
    )
    static let sampleGroceries = Transaction.Category(
        id: Id(),
        name: .init("Groceries")!,
        sfSymbol: .init("bag.fill")!,
        goal: .init(amount: Money(200)!, period: .week)
    )
    static let sampleHousing = Transaction.Category(
        id: Id(),
        name: .init("Housing")!,
        sfSymbol: .init("house.fill")!,
        goal: .init(amount: Money(1500)!, period: .month)
    )
    static let samplePaycheck = Transaction.Category(
        id: Id(),
        name: .init("Paycheck")!,
        sfSymbol: .init("banknote.fill")!,
        goal: .init(amount: Money(4000)!, period: .month, comparison: .greaterThan)
    )
    static let sampleTravel = Transaction.Category(
        id: Id(),
        name: .init("Travel")!,
        sfSymbol: .init("airplane")!,
        goal: .init(amount: Money(2000)!, period: .year)
    )
    static let sampleVehicle = Transaction.Category(
        id: Id(),
        name: .init("Vehicle")!,
        sfSymbol: .init("car.side.fill")!,
        goal: .init(amount: Money(500)!, period: .month)
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
