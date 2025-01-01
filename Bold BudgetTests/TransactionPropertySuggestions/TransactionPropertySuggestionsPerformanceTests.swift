//
//  TransactionPropertySuggestionsPerformanceTests.swift
//  Bold BudgetTests
//
//  Created by Jason Vance on 12/31/24.
//

import XCTest

final class TransactionPropertySuggestionsPerformanceTests: XCTestCase {
    
    var titles: [Transaction.Title] = [
        .init("Bracelet Charm")!,
        .init("Girls' Bracelets")!,
        .init("Breakfast")!,
        .init("Lunch")!,
        .init("Dinner")!,
        .init("Drink")!,
        .init("Milkshake")!,
        .init("Fried Rice")!,
        .init("Bread")!,
        .init("Veggies")!,
        .init("Cellphone")!,
        .init("Electricity")!,
        .init("Gas")!,
        .init("Kitchen Stuff")!,
        .init("Car")!,
        .init("Car Insurance")!,
        .init("Water Park")!,
        .init("Gym")!,
        .init("Snacks")!,
        .init("Gift")!,
        .init("Gift Card")!,
        .init("Water")!,
        .init("Heating")!,
        .init("Cooling")!,
        .init("Cleaning")!,
        .init("Other")!,
        .init("Earrings")!,
        .init("Necklace")!,
        .init("Bracelet")!,
    ]
    
    var locations: [Transaction.Location] = [
        .init("Home")!,
        .init("Work")!,
        .init("Store")!,
        .init("Park")!,
        .init("Restaurant")!,
        .init("Bar")!,
        .init("Cafe")!,
        .init("Gym")!,
        .init("Park")!,
        .init("Walmart")!,
        .init("Target")!,
        .init("Office")!,
        .init("School")!,
        .init("Panda Express")!,
        .init("Subway")!,
        .init("Coffee Shop")!,
        .init("Cafe")!,
        .init("McDonald's")!,
        .init("BRUG")!,
        .init("Five Guys")!,
        .init("Pizza Hut")!,
        .init("Costco")!,
        .init("RAKUMEN")!,
        .init("KFC")!,
        .init("Dunkin'")!,
        .init("Starbucks")!,
        .init("Infinitea")!,
        .init("Chipotle")!,
        .init("Chick-Fil-A")!,
        .init("Burger King")!,
    ]
    
    func testPerformanceOfEmptyPartialTransaction() throws {
        let loadsOfTransactions = (0...100000).map { _ in Transaction.sampleRandomBasic }
        
        self.measure {
            _ = TransactionPropertySuggestions.from(
                partialTransaction: PartialTransaction(title: nil, amount: nil, categoryId: nil, location: nil, tags: []),
                historicalTransactions: loadsOfTransactions
            )
        }
    }
    
    func testPerformanceOfPartialTransactionWithTitle() throws {
        let loadsOfTransactions = (0...100000).map { amount in
            Transaction(
                id: Transaction.Id(),
                title: Int.random(in: 1...3) % 3 == 0 ? nil : titles.randomElement(),
                amount: Money(Double(amount))!,
                date: .now,
                categoryId: Transaction.Category.samples.randomElement()!.id,
                location: Int.random(in: 1...3) % 3 == 0 ? nil : locations.randomElement()
            )
        }
        
        self.measure {
            _ = TransactionPropertySuggestions.from(
                partialTransaction: PartialTransaction(title: .init("Gas"), amount: nil, categoryId: nil, location: nil, tags: []),
                historicalTransactions: loadsOfTransactions
            )
        }
    }
    
    func testPerformanceOfPartialTransactionWithFewProps() throws {
        let loadsOfTransactions = (0...100000).map { amount in
            Transaction(
                id: Transaction.Id(),
                title: Int.random(in: 1...3) % 3 == 0 ? nil : titles.randomElement(),
                amount: Money(Double(amount))!,
                date: .now,
                categoryId: Transaction.Category.samples.randomElement()!.id,
                location: Int.random(in: 1...3) % 3 == 0 ? nil : locations.randomElement()
            )
        }
        
        self.measure {
            _ = TransactionPropertySuggestions.from(
                partialTransaction: PartialTransaction(
                    title: .init("Gas"),
                    amount: nil,
                    categoryId: Transaction.Category.samples.randomElement()!.id,
                    location: .init("Costco"),
                    tags: []
                ),
                historicalTransactions: loadsOfTransactions
            )
        }
    }

}
