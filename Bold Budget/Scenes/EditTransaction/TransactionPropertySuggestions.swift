//
//  TransactionPropertySuggestions.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/31/24.
//

import Foundation

struct TransactionPropertySuggestions {
    let titles: [Transaction.Title]
    let amounts: [Money]
    let categoryIds: [Transaction.Category.Id]
    let locations: [Transaction.Location]
    let tags: [Transaction.Tag]
    
    static let empty: TransactionPropertySuggestions = .init(
        titles: [], amounts: [], categoryIds: [], locations: [], tags: []
    )
}

extension TransactionPropertySuggestions {
    
    static func from(
        partialTransaction: PartialTransaction,
        historicalTransactions: [Transaction]
    ) -> TransactionPropertySuggestions {
        var titleCounts = [Transaction.Title:Int]()
        var amountCounts = [Money:Int]()
        var categoryCounts = [Transaction.Category.Id:Int]()
        var locationCounts = [Transaction.Location:Int]()
        var tagCounts = [Transaction.Tag:Int]()

        var partialTransactionWasEmpty: Bool = true
        
        if let title = partialTransaction.title {
            partialTransactionWasEmpty = false
            historicalTransactions
                .filter { title == $0.title }
                .forEach { transaction in
                    extractAmount(from: transaction, into: &amountCounts)
                    extractCategory(from: transaction, into: &categoryCounts)
                    extractLocation(from: transaction, into: &locationCounts)
                    extractTags(from: transaction, into: &tagCounts)
                }
        }
        if let amount = partialTransaction.amount {
            partialTransactionWasEmpty = false
            historicalTransactions
                .filter { amount == $0.amount }
                .forEach { transaction in
                    extractTitle(from: transaction, into: &titleCounts)
                    extractCategory(from: transaction, into: &categoryCounts)
                    extractLocation(from: transaction, into: &locationCounts)
                    extractTags(from: transaction, into: &tagCounts)
                }
        }
        if let categoryId = partialTransaction.categoryId {
            partialTransactionWasEmpty = false
            historicalTransactions
                .filter { categoryId == $0.categoryId }
                .forEach { transaction in
                    extractTitle(from: transaction, into: &titleCounts)
                    extractAmount(from: transaction, into: &amountCounts)
                    extractLocation(from: transaction, into: &locationCounts)
                    extractTags(from: transaction, into: &tagCounts)
                }
        }
        if let location = partialTransaction.location {
            partialTransactionWasEmpty = false
            historicalTransactions
                .filter { location == $0.location }
                .forEach { transaction in
                    extractTitle(from: transaction, into: &titleCounts)
                    extractAmount(from: transaction, into: &amountCounts)
                    extractCategory(from: transaction, into: &categoryCounts)
                    extractTags(from: transaction, into: &tagCounts)
                }
        }
        if !partialTransaction.tags.isEmpty {
            partialTransactionWasEmpty = false
            historicalTransactions
                .filter { !partialTransaction.tags.intersection($0.tags).isEmpty }
                .forEach { transaction in
                    extractTitle(from: transaction, into: &titleCounts)
                    extractAmount(from: transaction, into: &amountCounts)
                    extractCategory(from: transaction, into: &categoryCounts)
                    extractLocation(from: transaction, into: &locationCounts)
                }
        }
        
        if partialTransactionWasEmpty {
            historicalTransactions
                .forEach { transaction in
                    extractTitle(from: transaction, into: &titleCounts)
                    extractAmount(from: transaction, into: &amountCounts)
                    extractCategory(from: transaction, into: &categoryCounts)
                    extractLocation(from: transaction, into: &locationCounts)
                    extractTags(from: transaction, into: &tagCounts)
                }
        }

        return .init(
            titles: titleCounts.sorted(by: { $0.value > $1.value }).map(\.key),
            amounts: amountCounts.sorted(by: { $0.value > $1.value }).map(\.key),
            categoryIds: categoryCounts.sorted(by: { $0.value > $1.value }).map(\.key),
            locations: locationCounts.sorted(by: { $0.value > $1.value }).map(\.key),
            tags: tagCounts.sorted(by: { $0.value > $1.value }).map(\.key)
        )
    }
    
    fileprivate static func extractTitle(from transaction: Transaction, into titleCounts: inout [Transaction.Title:Int]) {
        if let title = transaction.title {
            titleCounts[title] = (titleCounts[title] ?? 0) + 1
        }
    }
    
    fileprivate static func extractAmount(from transaction: Transaction, into amountCounts: inout [Money:Int]) {
        amountCounts[transaction.amount] = (amountCounts[transaction.amount] ?? 0) + 1
    }
    
    fileprivate static func extractCategory(from transaction: Transaction, into categoryCounts: inout [Transaction.Category.Id:Int]) {
        categoryCounts[transaction.categoryId] = (categoryCounts[transaction.categoryId] ?? 0) + 1
    }
    
    fileprivate static func extractLocation(from transaction: Transaction, into locationCounts: inout [Transaction.Location:Int]) {
        if let location = transaction.location {
            locationCounts[location] = (locationCounts[location] ?? 0) + 1
        }
    }
    
    fileprivate static func extractTags(from transaction: Transaction, into tagCounts: inout [Transaction.Tag:Int]) {
        transaction.tags.forEach { tag in
            tagCounts[tag] = (tagCounts[tag] ?? 0) + 1
        }
    }
}
