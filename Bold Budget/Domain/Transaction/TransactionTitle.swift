//
//  TransactionTitle.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Foundation

extension Transaction {
    class Title {
        
        static let minTextLength: Int = 3
        static let maxTextLength: Int = 50

        let value: String
        
        init?(_ value: String) {
            // Trim whitespace
            let trimmedText = value.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for minimum and maximum length
            guard trimmedText.count >= Self.minTextLength, trimmedText.count <= Self.maxTextLength else {
                return nil
            }
            
            // Convert to lowercase
            self.value = trimmedText
        }
        
        static let sample: Transaction.Title = .init("Lorem ipsum dolor sit amet, consectetur adipiscing")!
    }
}

@objc(TransactionTitleValueTransformer)
class TransactionTitleValueTransformer: ValueTransformer {
    
    static let name = NSValueTransformerName(rawValue: String(describing: TransactionTitleValueTransformer.self))
    
    override class func transformedValueClass() -> AnyClass {
        return Transaction.Title.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value as? Transaction.Title else { return nil }
        let root = NSString(string: value.value)
        let data = try? NSKeyedArchiver.archivedData(withRootObject: root, requiringSecureCoding: true)
        return data
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        guard let value = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSString.self, from: data) else { return nil }
        return Transaction.Title(String(value))
    }
}
