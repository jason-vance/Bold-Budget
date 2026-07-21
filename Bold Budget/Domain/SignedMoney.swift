//
//  SignedMoney.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/21/26.
//

import Foundation

/// A currency amount that may be negative.
///
/// `Money` is deliberately non-negative and models the magnitude the user types on the keypad.
/// `SignedMoney` models values that carry direction — account balances (liabilities are negative),
/// net worth (can be underwater), and month-over-month deltas.
struct SignedMoney {

    typealias Amount = Double

    static let zero: SignedMoney = .init(0)

    let amount: Amount

    init(_ amount: Amount) {
        self.amount = amount
    }

    init(_ money: Money) {
        self.amount = money.amount
    }

    /// The non-negative magnitude of this value.
    var magnitude: Money { Money(abs(amount))! }

    var isNegative: Bool { amount < 0 }
    var isPositive: Bool { amount > 0 }

    func formatted(locale: Locale = .current) -> String {
        let currencyCode = locale.currency?.identifier ?? "USD"
        return amount.formatted(.currency(code: currencyCode))
    }

    /// A leading `+` / `−` sign followed by the magnitude, e.g. `+$39,489` / `−$156,538`.
    /// Zero renders without a sign.
    func formattedSigned(locale: Locale = .current) -> String {
        if amount > 0 { return "+" + magnitude.formatted(locale: locale) }
        if amount < 0 { return "−" + magnitude.formatted(locale: locale) }
        return magnitude.formatted(locale: locale)
    }

    static func + (lhs: SignedMoney, rhs: SignedMoney) -> SignedMoney {
        .init(lhs.amount + rhs.amount)
    }

    static func - (lhs: SignedMoney, rhs: SignedMoney) -> SignedMoney {
        .init(lhs.amount - rhs.amount)
    }

    static prefix func - (value: SignedMoney) -> SignedMoney {
        .init(-value.amount)
    }
}

extension SignedMoney: Comparable {
    static func < (lhs: SignedMoney, rhs: SignedMoney) -> Bool {
        lhs.amount < rhs.amount
    }
}

extension SignedMoney: Equatable {
    static func == (lhs: SignedMoney, rhs: SignedMoney) -> Bool {
        lhs.amount == rhs.amount
    }
}

extension SignedMoney: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
    }
}

extension Collection where Element == SignedMoney {
    var sum: SignedMoney {
        reduce(.zero, +)
    }
}
