//
//  TransactionCategorySfSymbol.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Foundation

extension Transaction.Category {
    class SfSymbol: Equatable {
        
        static func == (lhs: SfSymbol, rhs: SfSymbol) -> Bool {
            lhs.value == rhs.value
        }
        
        let value: String
        
        init?(_ value: String) {
            let trimmedText = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.contains(" ") else { return nil }
            self.value = trimmedText
        }
    }
}

@objc(TransactionCategorySfSymbolValueTransformer)
class TransactionCategorySfSymbolValueTransformer: ValueTransformer {
    
    static let name = NSValueTransformerName(rawValue: String(describing: TransactionCategorySfSymbolValueTransformer.self))
    
    override class func transformedValueClass() -> AnyClass {
        return Transaction.Category.SfSymbol.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let sfSymbol = value as? Transaction.Category.SfSymbol else { return nil }
        let root = NSString(string: sfSymbol.value)
        let data = try? NSKeyedArchiver.archivedData(withRootObject: root, requiringSecureCoding: true)
        return data
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        guard let sfSymbolValue = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSString.self, from: data) else { return nil }
        return Transaction.Category.SfSymbol(String(sfSymbolValue))
    }
}
