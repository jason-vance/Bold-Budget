//
//  TransactionCategoryRepo.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import Combine
import Foundation

protocol TransactionCategorySaver {
    func save(category: Transaction.Category)
}

class TransactionCategoryRepo {
    
    private static let envKey_useMocks: String = "TransactionCategoryRepo.envKey_useMocks"
    
    public static func set(useMocks: Bool = true, in environment: inout [String:String]) {
        environment[TransactionCategoryRepo.envKey_useMocks] = String(useMocks)
    }
    
    private static func shouldUseMocks() -> Bool {
        if let useMocks = ProcessInfo.processInfo.environment[Self.envKey_useMocks] {
            return Bool(useMocks) ?? false
        }
        return false
    }
    
    static var instance: TransactionCategoryRepo? = nil
    static func getInstance() -> TransactionCategoryRepo {
        if instance == nil {
            if Self.shouldUseMocks() {
                var categories = Transaction.Category.samples
                instance = .init(
                    getCategories: { categories },
                    addCategory: { categories = categories + [$0] }
                )
            } else {
                let cache = TransactionCategoriesCache()
                instance = .init(
                    getCategories: { cache.categories },
                    addCategory: { category in try cache.add(category: category) }
                )
            }
        }
        
        return instance!
    }
    
    private let getCategories: () -> [Transaction.Category]
    private let addCategory: (Transaction.Category) throws -> ()
    private let categoriesSubject: CurrentValueSubject<[Transaction.Category],Never> = .init([])

    init(
        getCategories: @escaping () -> [Transaction.Category],
        addCategory: @escaping (Transaction.Category) throws -> ()
    ) {
        self.getCategories = getCategories
        self.addCategory = addCategory
        categoriesSubject.send(getCategories())
    }
    
    public var categoriesPublisher: AnyPublisher<[Transaction.Category],Never> {
        categoriesSubject.eraseToAnyPublisher()
    }
    
    public var categories: [Transaction.Category] { categoriesSubject.value }
    
    func save(category: Transaction.Category) {
        do {
            try addCategory(category)
            categoriesSubject.send(getCategories())
        } catch {
            print("Failed to add category: \(error.localizedDescription)")
        }
    }
}

extension TransactionCategoryRepo: TransactionCategorySaver { }
