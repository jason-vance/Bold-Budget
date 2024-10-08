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
    
    init?(_ amount: Amount) {
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

extension Money {
    static var sampleRandom: Money {
        .init(.random(in: 1...250))!
    }
}

@objc(MoneyValueTransformer)
class MoneyValueTransformer: ValueTransformer {
    
    static let name = NSValueTransformerName(rawValue: String(describing: MoneyValueTransformer.self))
    
    override class func transformedValueClass() -> AnyClass {
        return Money.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value as? Money else { return nil }
        let root = NSNumber(value: value.amount)
        let data = try? NSKeyedArchiver.archivedData(withRootObject: root, requiringSecureCoding: true)
        return data
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        guard let value = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSNumber.self, from: data) else { return nil }
        return Money(Money.Amount(truncating: value))
    }
}
