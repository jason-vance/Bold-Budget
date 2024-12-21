//
//  Money.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation

class Money {
    
    typealias Amount = Double
    
    static let zero: Money = .init(0)!
    
    let amount: Amount
    
    init?(_ amount: Amount?) {
        guard let amount = amount else { return nil }
        guard amount >= 0 else { return nil }
        self.amount = amount
    }
    
    func formatted(locale: Locale = .current) -> String {
        let currencyCode = locale.currency?.identifier ?? "USD"
        return amount.formatted(.currency(code: currencyCode))
    }
    
    static func + (_ lhs: Money, rhs: Money) -> Money {
        Money(lhs.amount + rhs.amount)!
    }
}

extension Money: Equatable {
    static func == (lhs: Money, rhs: Money) -> Bool {
        lhs.amount == rhs.amount
    }
}

extension Money: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
    }
}

extension Money {
    static var sampleRandom: Money {
        .init(.random(in: 1...250))!
    }
}
