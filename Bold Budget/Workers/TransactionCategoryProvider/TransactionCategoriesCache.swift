//
//  TransactionCategoriesCache.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import Foundation

class TransactionCategoriesCache {
    
    private typealias CategoriesCache = Cache<UUID,Transaction.Category>
    private static let cacheName = "CategoriesCache"
    
    private let cache = Cache.readFromDiskOrDefault(CategoriesCache.self, withName: cacheName)
    
    public var categories: [Transaction.Category] {
        cache.values
    }
    
    public func add(category: Transaction.Category) {
        cache[category.id] = category
        try? cache.saveToDisk(withName: Self.cacheName)
    }
    
    subscript(id: UUID) -> Transaction.Category? {
        get { return cache[id] }
        set { cache[id] = newValue }
    }
}
