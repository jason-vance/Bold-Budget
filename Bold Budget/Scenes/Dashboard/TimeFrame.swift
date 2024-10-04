//
//  TimeFrame.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/3/24.
//

import Foundation

struct TimeFrame: Equatable {
    
    enum Period {
        case month
        case year
        
        func startContaining(_ date: SimpleDate) -> SimpleDate {
            switch self {
            case .month:
                SimpleDate.startOfMonth(containing: date)
            case .year:
                SimpleDate.startOfYear(containing: date)
            }
        }
        
        func endContaining(_ date: SimpleDate) -> SimpleDate {
            switch self {
            case .month:
                SimpleDate.endOfMonth(containing: date)
            case .year:
                SimpleDate.endOfYear(containing: date)
            }
        }
        
        func toUiString() -> String {
            switch self {
            case .month:
                return String(localized: "Month")
            case .year:
                return String(localized: "Year")
            }
        }
    }
    
    let period: Period
    let start: SimpleDate
    let end: SimpleDate
    
    init(period: Period, containing date: SimpleDate) {
        self.period = period
        self.start = period.startContaining(date)
        self.end = period.endContaining(date)
    }
    
    var next: TimeFrame {
        let endDate = end.toDate()!
        let endDatePlusOne = Calendar.current.date(byAdding: .day, value: 1, to: endDate)!
        let nextDate = SimpleDate(date: endDatePlusOne)!
        return TimeFrame(period: period, containing: nextDate)
    }
    
    var previous: TimeFrame {
        let startDate = start.toDate()!
        let startDateMinusOne = Calendar.current.date(byAdding: .day, value: -11, to: startDate)!
        let previousDate = SimpleDate(date: startDateMinusOne)!
        return TimeFrame(period: period, containing: previousDate)
    }
    
    func toUiString() -> String {
        let formatter = DateFormatter()
        
        switch period {
        case .month:
            formatter.dateFormat = "MMM yyyy"
        case .year:
            formatter.dateFormat = "yyyy"
        }
        
        return formatter.string(from: start.toDate()!)
    }
}
