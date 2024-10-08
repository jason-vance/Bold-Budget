//
//  TransactionLocation.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Foundation

extension Transaction {
    class Location {
        
        static let minTextLength: Int = 3
        static let maxTextLength: Int = 100

        let value: String
        
        init?(_ value: String) {
            // Trim whitespace
            let trimmedText = value.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for minimum and maximum length
            guard trimmedText.count >= Self.minTextLength, trimmedText.count <= Self.maxTextLength else {
                return nil
            }
            
            // Starts and ends with a letter
            guard let first = trimmedText.first, let last = trimmedText.last else { return nil }
            guard first.isLetter, last.isLetter else { return nil }
            
            // Convert to lowercase
            self.value = trimmedText
        }
        
        static let sample: Transaction.Location = .init("Cupertino, CA")!
    }
}

@objc(TransactionLocationValueTransformer)
class TransactionLocationValueTransformer: ValueTransformer {
    
    static let name = NSValueTransformerName(rawValue: String(describing: TransactionLocationValueTransformer.self))
    
    override class func transformedValueClass() -> AnyClass {
        return Transaction.Location.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value as? Transaction.Location else { return nil }
        let root = NSString(string: value.value)
        let data = try? NSKeyedArchiver.archivedData(withRootObject: root, requiringSecureCoding: true)
        return data
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        guard let value = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSString.self, from: data) else { return nil }
        return Transaction.Location(String(value))
    }
}
