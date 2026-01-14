//
//  TimeFrame.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/3/24.
//

import Foundation

struct TimeFrame: Equatable {
    
    enum Period: String {
        case week
        case month
        case year
        
        func startContaining(_ date: SimpleDate) -> SimpleDate {
            switch self {
            case .week:
                SimpleDate.startOfWeek(containing: date)
            case .month:
                SimpleDate.startOfMonth(containing: date)
            case .year:
                SimpleDate.startOfYear(containing: date)
            }
        }
        
        func endContaining(_ date: SimpleDate) -> SimpleDate {
            switch self {
            case .week:
                SimpleDate.endOfWeek(containing: date)
            case .month:
                SimpleDate.endOfMonth(containing: date)
            case .year:
                SimpleDate.endOfYear(containing: date)
            }
        }
        
        func toUiString() -> String {
            switch self {
            case .week:
                return String(localized: "Week")
            case .month:
                return String(localized: "Month")
            case .year:
                return String(localized: "Year")
            }
        }
        
        func number(in other: Period) -> Double {
            switch self {
            case .week:
                switch other {
                case .week: return 1
                case .month: return 4
                case .year: return 52
                }
            case .month:
                switch other {
                case .week: return 0.25
                case .month: return 1
                case .year: return 12
                }
            case .year:
                switch other {
                case .week: return 1/52.0
                case .month: return 1/12.0
                case .year: return 1
                }
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
        case .week:
            formatter.dateFormat = "d MMM yy"
            return "\(formatter.string(from: start.toDate()!)) - \(formatter.string(from: end.toDate()!))"
        case .month:
            formatter.dateFormat = "MMM yyyy"
        case .year:
            formatter.dateFormat = "yyyy"
        }
        
        return formatter.string(from: start.toDate()!)
    }
}
