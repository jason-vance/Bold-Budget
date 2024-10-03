//
//  SimpleDate.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Foundation

struct SimpleDate {
    
    public typealias RawValue = UInt32
    
    let rawValue: RawValue
    
    // Initialize with a rawValue
    init?(rawValue: RawValue) {
        // Extract year, month, and day from rawValue
        let year = Int(rawValue / 10000)
        let month = Int((rawValue % 10000) / 100)
        let day = Int(rawValue % 100)
        
        // Ensure year, month, and day are valid
        guard year >= 0, year <= 9999,
              month >= 1, month <= 12,
              day >= 1, day <= 31 else {
            return nil
        }
        
        // Create DateComponents and verify it's a valid date
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        let calendar = Calendar.current
        if calendar.date(from: components) == nil {
            return nil // Invalid date
        }
        
        // Set the rawValue if everything is valid
        self.rawValue = rawValue
    }
    
    init?(date: Date) {
        let calendar = Calendar.current
        
        // Extract year, month, and day components from the date
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        // Ensure the year fits within the range for UInt32 (which it will, assuming reasonable dates)
        guard year >= 0, year <= 9999,
              month >= 1, month <= 12,
              day >= 1, day <= 31 else {
            return nil
        }
        
        // Combine year, month, and day into a UInt32 in the format yyyymmdd
        self.rawValue = UInt32(year * 10000 + month * 100 + day)
    }
    
    // Function to convert rawValue back to Date
    func toDate() -> Date? {
        // Extract year, month, and day from rawValue
        let year = Int(rawValue / 10000)
        let month = Int((rawValue % 10000) / 100)
        let day = Int(rawValue % 100)
        
        // Create a DateComponents instance
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        // Convert DateComponents to Date using Calendar
        let calendar = Calendar.current
        return calendar.date(from: components)
    }
    
    static var now: SimpleDate { .init(date: .now)! }
}
