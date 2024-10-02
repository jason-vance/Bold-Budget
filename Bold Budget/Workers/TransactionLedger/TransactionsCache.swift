//
//  TransactionsCache.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import Foundation

class TransactionsCache {
    
    private typealias TransactionsCache = Cache<UUID,TransactionsCacheEntry>
    private static let cacheName = "TransactionsCache"
    
    private let cache = Cache.readFromDiskOrDefault(TransactionsCache.self, withName: cacheName)
    
    private let categoryProvider: TransactionCategoryProvider
    
    init(categoryProvider: TransactionCategoryProvider) {
        self.categoryProvider = categoryProvider
    }

    public var transactions: [Transaction] {
        let categoryDict = makeCategoryDict()
        return cache.values.compactMap { $0.toTransaction(categories: categoryDict) }
    }
    
    private func makeCategoryDict() -> [UUID:Transaction.Category] {
        Dictionary(uniqueKeysWithValues: categoryProvider.categories.map { ($0.id, $0) })
    }
    
    public func add(transaction: Transaction) {
        cache[transaction.id] = .from(transaction)
        try? cache.saveToDisk(withName: Self.cacheName)
    }
}

fileprivate extension TransactionsCache {
    struct TransactionsCacheEntry: Codable {
        let id: UUID?
        let title: String?
        let amount: Double?
        let date: Date?
        let categoryId: UUID?
        
        static func from(_ transaction: Transaction) -> TransactionsCacheEntry {
            .init(
                id: transaction.id,
                title: transaction.title,
                amount: transaction.amount.amount,
                date: transaction.date,
                categoryId: transaction.category.id
            )
        }
        
        func toTransaction(categories: [UUID:Transaction.Category]) -> Transaction? {
            guard let id = id else { return nil }
            guard let amount = amount else { return nil }
            guard let amount = Money(amount) else { return nil }
            guard let date = date else { return nil }
            guard let categoryId = categoryId else { return nil }
            guard let category = categories[categoryId] else { return nil }
            
            return .init(
                id: id,
                title: title,
                amount: amount,
                date: date,
                category: category
            )
        }
    }
}
