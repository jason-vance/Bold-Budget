//
//  Transaction.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation

struct Transaction: Identifiable {
    let id: UUID
    //TODO: Use TransactionDescription struct
    let title: String
    let amount: Money
    let date: Date
    let category: Category
    
    var description: String {
        //TODO: Add category, etc
        return title
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
            title: "Walmart Groceries",
            amount: Money(.random(in: 1...250))!,
            date: .now,
            category: Category.samples[.random(in: 0..<Category.samples.count)]
        )
    }
}
