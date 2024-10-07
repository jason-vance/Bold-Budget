//
//  TransactionCategoryRepo.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import Combine
import Foundation

protocol TransactionCategorySaver {
    func save(newCategory: Transaction.Category)
}

class TransactionCategoryRepo {
    
    static var instance: TransactionCategoryRepo? = nil
    static func getInstance() -> TransactionCategoryRepo {
        if instance == nil {
            if let testInstance = getTestInstance() {
                instance = testInstance
            } else {
                instance = getDefaultInstance()
            }
        }
        
        return instance!
    }
    
    private static func getDefaultInstance() -> TransactionCategoryRepo {
        let cache = TransactionCategoriesCache()
        return .init(
            getCategories: { cache.categories },
            addOrUpdateCategory: { try cache.addOrUpdate(category: $0) }
        )
    }
    
    private let getCategories: () -> [Transaction.Category]
    private let addOrUpdateCategory: (Transaction.Category) throws -> ()
    private let categoriesSubject: CurrentValueSubject<[Transaction.Category],Never> = .init([])

    init(
        getCategories: @escaping () -> [Transaction.Category],
        addOrUpdateCategory: @escaping (Transaction.Category) throws -> ()
    ) {
        self.getCategories = getCategories
        self.addOrUpdateCategory = addOrUpdateCategory
        categoriesSubject.send(getCategories())
    }
    
    public var categoriesPublisher: AnyPublisher<[Transaction.Category],Never> {
        categoriesSubject.eraseToAnyPublisher()
    }
    
    public var categories: [Transaction.Category] { categoriesSubject.value }
    
    func save(newCategory: Transaction.Category) {
        do {
            try addOrUpdateCategory(newCategory)
            categoriesSubject.send(getCategories())
        } catch {
            print("Failed to add category: \(error.localizedDescription)")
        }
    }
}

extension TransactionCategoryRepo: TransactionCategorySaver { }

extension TransactionCategoryRepo {
    public enum TestCategories: String, RawRepresentable {
        case empty
        case categorySamples
    }
    
    private static let envKey_TestCategories: String = "TransactionCategoryRepo.envKey_TestCategories"
    
    public static func test(using testCategories: TestCategories = .categorySamples, in environment: inout [String:String]) {
        environment[TransactionCategoryRepo.envKey_TestCategories] = testCategories.rawValue
    }
    
    private static func getTestCategories() -> [Transaction.Category]? {
        if let testCategories = TestCategories(rawValue: ProcessInfo.processInfo.environment[Self.envKey_TestCategories] ?? "") {
            switch testCategories {
            case .empty:
                return []
            case .categorySamples:
                return Transaction.Category.samples
            }
        }
        return nil
    }
    
    private static func getTestInstance() -> TransactionCategoryRepo? {
        if var testCategories = Self.getTestCategories() {
            return .init(
                getCategories: { testCategories },
                addOrUpdateCategory: { testCategories = testCategories + [$0] }
            )
        }
        return nil
    }
}
