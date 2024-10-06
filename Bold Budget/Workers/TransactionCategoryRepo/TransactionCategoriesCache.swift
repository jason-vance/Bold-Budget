//
//  TransactionCategoriesCache.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import Foundation

class TransactionCategoriesCache {
    
    private typealias CategoriesCache = Cache<UUID,TransactionCategoriesCacheEntry>
    private static let cacheName = "CategoriesCache"
    
    private let cache = Cache.readFromDiskOrDefault(CategoriesCache.self, withName: cacheName)
    
    public var categories: [Transaction.Category] {
        cache.values.compactMap { $0.toCategory() }
    }
    
    public func addOrUpdate(category: Transaction.Category) throws {
        cache[category.id] = .from(category)
        try cache.saveToDisk(withName: Self.cacheName)
    }
    
    subscript(id: UUID) -> Transaction.Category? {
        get { return cache[id]?.toCategory() }
        set {
            if let newValue = newValue {
                cache[id] = .from(newValue)
            } else {
                cache[id] = nil
            }
        }
    }
}

fileprivate extension TransactionCategoriesCache {
    struct TransactionCategoriesCacheEntry: Codable {
        let id: UUID?
        let kind: Transaction.Category.Kind?
        let name: String?
        let sfSymbol: String?

        static func from(_ category: Transaction.Category) -> TransactionCategoriesCacheEntry {
            .init(
                id: category.id,
                kind: category.kind,
                name: category.name.value,
                sfSymbol: category.sfSymbol.value
            )
        }
        
        func toCategory() -> Transaction.Category? {
            guard let id = id else { return nil }
            guard let kind = kind else { return nil }
            guard let name = name else { return nil }
            guard let name = Transaction.Category.Name(name) else { return nil }
            guard let sfSymbol = sfSymbol else { return nil }
            guard let sfSymbol = Transaction.Category.SfSymbol(sfSymbol) else { return nil }
            
            return .init(
                id: id,
                kind: kind,
                name: name,
                sfSymbol: sfSymbol
            )
        }
    }
}

