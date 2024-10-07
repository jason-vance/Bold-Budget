//
//  Transaction.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation

struct Transaction: Identifiable {
    
    let id: UUID
    let title: Transaction.Title?
    let amount: Money
    let date: SimpleDate
    let category: Transaction.Category
    let location: Transaction.Location?
    
    var description: String {
        return title?.text ?? category.name.value
    }
}

extension Transaction {
    static var sampleRandomBasic: Transaction {
        .init(
            id: UUID(),
            title: .sample,
            amount: .sampleRandom,
            date: .now,
            category: Category.samples[.random(in: 0..<Category.samples.count)],
            location: .sample
        )
    }
    
    static var samples: [Transaction] {
        (0...100).map { _ in Transaction.sampleRandomBasic }
    }
    
    static let screenshotSamples: [Transaction] = [
        .init(
            id: UUID(),
            title: .init("Movie Tickets")!,
            amount: .init(47.52)!,
            date: .now,
            category: .sampleEntertainment,
            location: .init("Redmond, WA")
        ),
        .init(
            id: UUID(),
            title: .init("Walmart")!,
            amount: .init(87.63)!,
            date: .now,
            category: .sampleGroceries,
            location: .init("Seattle, WA")
        ),
        .init(
            id: UUID(),
            title: .init("Rent"),
            amount: .init(750)!,
            date: .now,
            category: .sampleHousing,
            location: nil
        ),
        .init(
            id: UUID(),
            title: .init("Paycheck")!,
            amount: .init(1084.62)!,
            date: .now,
            category: .samplePaycheck,
            location: nil
        ),
        .init(
            id: UUID(),
            title: .init("Gas"),
            amount: .init(57.30)!,
            date: .now,
            category: .sampleVehicle,
            location: .init("Redmond, WA")
        ),
        .init(
            id: UUID(),
            title: .init("Walmart")!,
            amount: .init(65.24)!,
            date: .startOfMonth(containing: .now),
            category: .sampleGroceries,
            location: .init("Seattle, WA")
        ),
    ]
}
