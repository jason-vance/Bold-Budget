//
//  SimpleDate.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Foundation

class SimpleDate {
    
    public typealias RawValue = UInt32
    
    static var now: SimpleDate { .init(date: .now)! }
    
    let rawValue: RawValue
    
    var year: Int { Int(rawValue / 10000) }
    var month: Int { Int((rawValue % 10000) / 100) }
    var day: Int { Int(rawValue % 100) }
    
    init?(rawValue: RawValue) {
        let year = Int(rawValue / 10000)
        let month = Int((rawValue % 10000) / 100)
        let day = Int(rawValue % 100)
        
        // Create DateComponents and verify it's a valid date
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        let calendar = Calendar.current
        if calendar.date(from: components) == nil {
            return nil // Invalid date
        }
        
        self.rawValue = rawValue
    }
    
    init?(year: Int, month: Int, day: Int) {
        guard year >= 0, year <= 9999,
              month >= 1, month <= 12,
              day >= 1, day <= 31 else {
            return nil
        }
        
        // Combine year, month, and day into a UInt32 in the format yyyymmdd
        self.rawValue = UInt32(year * 10000 + month * 100 + day)
    }
    
    init?(date: Date) {
        let calendar = Calendar.current
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        // Ensure the year fits within the range for UInt32 (which it will, assuming reasonable dates)
        guard year >= 0, year <= 9999 else {
            return nil
        }
        
        // Combine year, month, and day into a UInt32 in the format yyyymmdd
        self.rawValue = UInt32(year * 10000 + month * 100 + day)
    }
    
    // Function to convert rawValue back to Date
    func toDate() -> Date? {
        // Create a DateComponents instance
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        // Convert DateComponents to Date using Calendar
        let calendar = Calendar.current
        return calendar.date(from: components)
    }
}

extension SimpleDate {
    
    static func startOfWeek(containing date: SimpleDate) -> SimpleDate {
        // Convert SimpleDate to Date
        let inputDate = date.toDate()!
        
        // Use Calendar to find the start of the week (respects locale)
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .weekOfYear, for: inputDate)!
        
        return SimpleDate(date: interval.start)!
    }
    
    static func endOfWeek(containing date: SimpleDate) -> SimpleDate {
        // Get the start of the week
        let startOfWeek = startOfWeek(containing: date)
        
        // Add 6 days to the start date to get the end date
        let calendar = Calendar.current
        let endOfWeekDate = calendar.date(byAdding: .day, value: 6, to: startOfWeek.toDate()!)!
        
        return SimpleDate(date: endOfWeekDate)!
    }
    
    static func startOfMonth(containing date: SimpleDate) -> SimpleDate {
        let rawValue = date.rawValue - (date.rawValue % 100) + 1
        return SimpleDate(rawValue: rawValue)!
    }
    
    static func endOfMonth(containing date: SimpleDate) -> SimpleDate {
        let startOfMonth = startOfMonth(containing: date)
        let startOfNext = Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth.toDate()!)
        return .init(date: Calendar.current.date(byAdding: .day, value: -1, to: startOfNext!)!)!
    }
    
    static func startOfYear(containing date: SimpleDate) -> SimpleDate {
        let rawValue = date.rawValue - (date.rawValue % 10000) + 101
        return SimpleDate(rawValue: rawValue)!
    }
    
    static func endOfYear(containing date: SimpleDate) -> SimpleDate {
        let startOfMonth = startOfYear(containing: date)
        let startOfNext = Calendar.current.date(byAdding: .year, value: 1, to: startOfMonth.toDate()!)
        return .init(date: Calendar.current.date(byAdding: .day, value: -1, to: startOfNext!)!)!
    }
}

extension SimpleDate: Equatable {
    static func == (lhs: SimpleDate, rhs: SimpleDate) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

extension SimpleDate: Comparable {
    static func < (lhs: SimpleDate, rhs: SimpleDate) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension SimpleDate: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
