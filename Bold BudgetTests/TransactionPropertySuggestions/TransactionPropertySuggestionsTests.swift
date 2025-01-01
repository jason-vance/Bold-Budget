//
//  TransactionPropertySuggestionsTests.swift
//  Bold BudgetTests
//
//  Created by Jason Vance on 12/31/24.
//

import Testing
import Foundation

struct TransactionPropertySuggestionsTests {
    
    private var entertainmentCategoryId = Transaction.Category.Id()
    private var groceryCategoryId = Transaction.Category.Id()

    private var subscriptionTag: Transaction.Tag { Transaction.Tag("Subscription")! }
    
    private var netflixTransaction: Transaction {
        Transaction(
            id: Transaction.Id(),
            title: Transaction.Title("Netflix"),
            amount: Money(24.07)!,
            date: .now,
            categoryId: entertainmentCategoryId,
            location: nil,
            tags: [subscriptionTag]
        )
    }
    
    private var walmartGroceriesTransaction: Transaction {
        Transaction(
            id: Transaction.Id(),
            title: nil,
            amount: Money(123.45)!,
            date: .now,
            categoryId: groceryCategoryId,
            location: Transaction.Location("Walmart"),
            tags: []
        )
    }
    
    private var timesGroceriesTransaction: Transaction {
        Transaction(
            id: Transaction.Id(),
            title: Transaction.Title("Veggies"),
            amount: Money(67.89)!,
            date: .now,
            categoryId: groceryCategoryId,
            location: Transaction.Location("Times"),
            tags: []
        )
    }
    
    @Test func noHistoricalTransactionsYieldNoSuggestions() async throws {
        let suggestions = TransactionPropertySuggestions.from(
            partialTransaction: PartialTransaction(title: nil, amount: nil, categoryId: nil, location: nil, tags: []),
            historicalTransactions: []
        )
        
        #expect(suggestions.titles.isEmpty)
        #expect(suggestions.amounts.isEmpty)
        #expect(suggestions.categoryIds.isEmpty)
        #expect(suggestions.locations.isEmpty)
        #expect(suggestions.tags.isEmpty)
    }
    
    @Test func emptyPartialTransactionYieldAllSuggestions() async throws {
        let suggestions = TransactionPropertySuggestions.from(
            partialTransaction: PartialTransaction(title: nil, amount: nil, categoryId: nil, location: nil, tags: []),
            historicalTransactions: [netflixTransaction, walmartGroceriesTransaction, timesGroceriesTransaction]
        )
        
        #expect(suggestions.titles.count == 2)
        #expect(suggestions.titles.contains(Transaction.Title("Netflix")!))
        #expect(suggestions.titles.contains(Transaction.Title("Veggies")!))

        #expect(suggestions.amounts.count == 3)
        #expect(suggestions.amounts.contains(Money(24.07)!))
        #expect(suggestions.amounts.contains(Money(123.45)!))
        #expect(suggestions.amounts.contains(Money(67.89)!))
        
        #expect(suggestions.categoryIds.count == 2)
        #expect(suggestions.categoryIds.contains(entertainmentCategoryId))
        #expect(suggestions.categoryIds.contains(groceryCategoryId))
        
        #expect(suggestions.locations.count == 2)
        #expect(suggestions.locations.contains(Transaction.Location("Walmart")!))
        #expect(suggestions.locations.contains(Transaction.Location("Times")!))
        
        #expect(suggestions.tags.count == 1)
        #expect(suggestions.tags.contains(subscriptionTag))
    }
    
    @Test func netflixTitleYieldNetflixSuggestions() async throws {
        let suggestions = TransactionPropertySuggestions.from(
            partialTransaction: PartialTransaction(title: Transaction.Title("Netflix"), amount: nil, categoryId: nil, location: nil, tags: []),
            historicalTransactions: [netflixTransaction, walmartGroceriesTransaction, timesGroceriesTransaction]
        )
        
        #expect(suggestions.amounts.count == 1)
        #expect(suggestions.amounts.contains(Money(24.07)!))
        
        #expect(suggestions.categoryIds.count == 1)
        #expect(suggestions.categoryIds.contains(entertainmentCategoryId))
        
        #expect(suggestions.locations.isEmpty)
        
        #expect(suggestions.tags.count == 1)
        #expect(suggestions.tags.contains(subscriptionTag))
    }
    
    @Test func groceryCategoryYieldGrocerySuggestions() async throws {
        let suggestions = TransactionPropertySuggestions.from(
            partialTransaction: PartialTransaction(title: nil, amount: nil, categoryId: groceryCategoryId, location: nil, tags: []),
            historicalTransactions: [netflixTransaction, walmartGroceriesTransaction, timesGroceriesTransaction]
        )
        
        #expect(suggestions.titles.count == 1)
        #expect(suggestions.titles.contains(Transaction.Title("Veggies")!))
        
        #expect(suggestions.amounts.count == 2)
        #expect(suggestions.amounts.contains(Money(123.45)!))
        #expect(suggestions.amounts.contains(Money(67.89)!))
        
        #expect(suggestions.locations.count == 2)
        #expect(suggestions.locations.contains(Transaction.Location("Walmart")!))
        #expect(suggestions.locations.contains(Transaction.Location("Times")!))
        
        #expect(suggestions.tags.isEmpty)
    }
}
