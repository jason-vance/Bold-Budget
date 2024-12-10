//
//  Transaction.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation

struct Transaction: Identifiable {
    
    let id: Id
    let title: Transaction.Title?
    let amount: Money
    let date: SimpleDate
    let category: Transaction.Category
    let location: Transaction.Location?
    let tags: Set<Transaction.Tag>
    
    var description: String { title?.value ?? category.name.value }
    
    init(
        id: Id,
        title: Transaction.Title? = nil,
        amount: Money,
        date: SimpleDate,
        category: Transaction.Category,
        location: Transaction.Location? = nil,
        tags: Set<Transaction.Tag> = []
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.location = location
        self.tags = tags
    }
}

extension Transaction {
    typealias Id = UUID
}

extension Transaction {
    static var sampleRandomBasic: Transaction {
        .init(
            id: Id(),
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
    
    static var samplesOnlyInGroceriesCategory: [Transaction] {
        samples.map { _ in
            let t = Transaction.sampleRandomBasic
            return .init(
                id: t.id,
                title: t.title,
                amount: t.amount,
                date: t.date,
                category: .sampleGroceries,
                location: t.location,
                tags: t.tags
            )
        }
    }
    
    static let screenshotSamples: [Transaction] = [
        .init(
            id: Id(),
            title: .init("Movie Tickets")!,
            amount: .init(47.52)!,
            date: .now,
            category: .sampleEntertainment,
            location: .init("Redmond, WA")
        ),
        .init(
            id: Id(),
            title: .init("Walmart")!,
            amount: .init(87.63)!,
            date: .now,
            category: .sampleGroceries,
            location: .init("Seattle, WA")
        ),
        .init(
            id: Id(),
            title: .init("Rent"),
            amount: .init(750)!,
            date: .now,
            category: .sampleHousing
        ),
        .init(
            id: Id(),
            title: .init("Paycheck")!,
            amount: .init(1084.62)!,
            date: .now,
            category: .samplePaycheck
        ),
        .init(
            id: Id(),
            title: .init("Gas"),
            amount: .init(57.30)!,
            date: .now,
            category: .sampleVehicle,
            location: .init("Redmond, WA")
        ),
        .init(
            id: Id(),
            title: .init("Walmart")!,
            amount: .init(65.24)!,
            date: .startOfMonth(containing: .now),
            category: .sampleGroceries,
            location: .init("Seattle, WA")
        ),
    ]
}
