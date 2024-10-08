//
//  TransactionCategoryName.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Foundation

extension Transaction.Category {
    class Name: Equatable {
        
        static let minTextLength: Int = 3
        static let maxTextLength: Int = 20
        
        var value: String
        
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
        
        static func == (lhs: Name, rhs: Name) -> Bool {
            lhs.value == rhs.value
        }
        
        static let sample: Transaction.Category.Name = .init("Groceries")!
    }
}

@objc(TransactionCategoryNameValueTransformer)
class TransactionCategoryNameValueTransformer: ValueTransformer {
    
    static let name = NSValueTransformerName(rawValue: String(describing: TransactionCategoryNameValueTransformer.self))

    override class func transformedValueClass() -> AnyClass {
        return Transaction.Category.Name.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let name = value as? Transaction.Category.Name else { return nil }
        let root = NSString(string: name.value)
        let data = try? NSKeyedArchiver.archivedData(withRootObject: root, requiringSecureCoding: true)
        return data
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        guard let nameValue = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSString.self, from: data) else { return nil }
        return Transaction.Category.Name(String(nameValue))
    }
}
