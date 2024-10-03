//
//  Transaction.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation

struct Transaction: Identifiable {
    
    enum Kind: Codable {
        case expense
        case income
    }
    
    let id: UUID
    let kind: Kind
    let title: Transaction.Title?
    let amount: Money
    let date: SimpleDate
    let category: Transaction.Category
    let cityAndState: Transaction.CityAndState?
    
    var description: String {
        return title?.text ?? category.name.value
    }
    
    var location: String? {
        return cityAndState?.value
    }
}

extension Transaction {
    static var sampleRandomBasic: Transaction {
        .init(
            id: UUID(),
            kind: .expense,
            title: .sample,
            amount: .sampleRandom,
            date: .now,
            category: Category.samples[.random(in: 0..<Category.samples.count)],
            cityAndState: .sample
        )
    }
    
    static var samples: [Transaction] {
        (0...100).map { _ in Transaction.sampleRandomBasic }
    }
}
