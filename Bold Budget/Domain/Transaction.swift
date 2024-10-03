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
    let date: Date
    let category: Transaction.Category
    
    var description: String {
        return title?.text ?? category.name.value
    }
    
    var location: String? {
        //TODO: Add location, address, etc
        return nil
    }
}

extension Transaction {
    static var sampleRandomBasic: Transaction {
        .init(
            id: UUID(),
            title: .init("Walmart Groceries")!,
            amount: Money(.random(in: 1...250))!,
            date: .now,
            category: Category.samples[.random(in: 0..<Category.samples.count)]
        )
    }
}
