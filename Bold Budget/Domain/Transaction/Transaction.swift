//
//  Transaction.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation
import SwiftData

@Model
class Transaction: Identifiable {
    
    @Attribute(.unique)
    var id: UUID
    
    @Attribute(.transformable(by: TransactionTitleValueTransformer.self))
    var title: Transaction.Title?
    
    @Attribute(.transformable(by: MoneyValueTransformer.self))
    var amount: Money
    
    @Attribute(.transformable(by: SimpleDateValueTransformer.self))
    var date: SimpleDate
    
    @Relationship(deleteRule: .noAction)
    var category: Transaction.Category
    
    @Attribute(.transformable(by: TransactionLocationValueTransformer.self))
    var location: Transaction.Location?
    
    var tags: [Transaction.Tag]?
    
    var description: String { title?.value ?? category.name.value }
    
    init(
        id: UUID,
        title: Transaction.Title? = nil,
        amount: Money,
        date: SimpleDate,
        category: Transaction.Category,
        location: Transaction.Location? = nil,
        tags: [Transaction.Tag] = []
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
    
    static var samplesOnlyInGroceriesCategory: [Transaction] {
        samples.map { _ in
            let t = Transaction.sampleRandomBasic
            t.category = .sampleGroceries
            return t
        }
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
            category: .sampleHousing
        ),
        .init(
            id: UUID(),
            title: .init("Paycheck")!,
            amount: .init(1084.62)!,
            date: .now,
            category: .samplePaycheck
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
