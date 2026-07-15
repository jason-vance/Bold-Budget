//
//  RecurringExpense.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/15/26.
//

import Foundation

struct RecurringExpense: Identifiable {

    enum Kind: String, Codable, CaseIterable {
        case debt
        case bill
        case subscription

        var name: String {
            switch self {
            case .debt:
                String(localized: "Debt")
            case .bill:
                String(localized: "Bill")
            case .subscription:
                String(localized: "Subscription")
            }
        }

        var pluralName: String {
            switch self {
            case .debt:
                String(localized: "Debts")
            case .bill:
                String(localized: "Bills")
            case .subscription:
                String(localized: "Subscriptions")
            }
        }
    }

    let id: Id
    let name: Name
    let kind: Kind
    let price: Money
    let monthsPerCycle: Int
    let remainingBalance: Money?
    let categoryId: Transaction.Category.Id?

    init(
        id: Id,
        name: Name,
        kind: Kind,
        price: Money,
        monthsPerCycle: Int = 1,
        remainingBalance: Money? = nil,
        categoryId: Transaction.Category.Id? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.price = price
        self.monthsPerCycle = max(1, monthsPerCycle)
        self.remainingBalance = remainingBalance
        self.categoryId = categoryId
    }

    var monthlyCost: Money {
        price / Double(monthsPerCycle)
    }
}

extension RecurringExpense {
    typealias Id = UUID
}

extension RecurringExpense: Equatable { }

extension RecurringExpense: Hashable { }

extension Collection where Element == RecurringExpense {

    var totalMonthlyCost: Money {
        reduce(.zero) { $0 + $1.monthlyCost }
    }

    var totalRemainingBalance: Money {
        compactMap(\.remainingBalance).reduce(.zero, +)
    }
}

extension RecurringExpense {

    static let sampleCarLoan: RecurringExpense = .init(
        id: Id(),
        name: .init("CX-30")!,
        kind: .debt,
        price: Money(458)!,
        remainingBalance: Money(28179)!
    )

    static let sampleRent: RecurringExpense = .init(
        id: Id(),
        name: .init("Rent")!,
        kind: .bill,
        price: Money(3400)!
    )

    static let sampleAnnualSubscription: RecurringExpense = .init(
        id: Id(),
        name: .init("Apple Developer")!,
        kind: .subscription,
        price: Money(99)!,
        monthsPerCycle: 12
    )

    static var samples: [RecurringExpense] {
        [
            sampleCarLoan,
            .init(
                id: Id(),
                name: .init("Pilot")!,
                kind: .debt,
                price: Money(548)!,
                remainingBalance: Money(17810)!
            ),
            sampleRent,
            .init(
                id: Id(),
                name: .init("Health Insurance")!,
                kind: .bill,
                price: Money(975)!
            ),
            .init(
                id: Id(),
                name: .init("Internet")!,
                kind: .bill,
                price: Money(130)!
            ),
            sampleAnnualSubscription,
            .init(
                id: Id(),
                name: .init("Netflix")!,
                kind: .subscription,
                price: Money(7.99)!
            ),
        ]
    }
}
