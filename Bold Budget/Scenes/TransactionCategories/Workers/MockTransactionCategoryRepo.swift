//
//  MockTransactionCategoryRepo.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import Combine
import Foundation

class MockTransactionCategoryRepo {
    
    private let categoriesSubject: CurrentValueSubject<[Transaction.Category],Never> = .init([])

    init(
        initialCategories: [Transaction.Category]
    ) {
        categoriesSubject.send(initialCategories)
    }
    
    public var categoriesPublisher: AnyPublisher<[Transaction.Category],Never> {
        categoriesSubject.eraseToAnyPublisher()
    }
    
    public var categories: [Transaction.Category] { categoriesSubject.value }
    
    func save(category: Transaction.Category) {
        if alreadyExists(category) {
            update(category: category)
        } else {
            insert(category: category)
        }
    }
    
    private func alreadyExists(_ category: Transaction.Category) -> Bool {
        categories.first { $0.id == category.id } != nil
    }
    
    private func update(category: Transaction.Category) {
        categoriesSubject.send(categories.filter { $0.id != category.id }) // Ensures updates if receivers depend on a change of Category.id
        categoriesSubject.send(categories + [category])
    }
    
    private func insert(category: Transaction.Category) {
        categoriesSubject.send(categoriesSubject.value + [category])
    }
}

extension MockTransactionCategoryRepo: TransactionCategorySaver {
    func save(category: Transaction.Category, to budget: Budget) async throws {
        save(category: category)
    }
}

extension MockTransactionCategoryRepo: TransactionCategoryFetcher {
    func fetchTransactionCategories(in budget: Budget) async throws -> [Transaction.Category] {
        categories
    }
}

extension MockTransactionCategoryRepo {
    
    public enum TestCategories: String, RawRepresentable {
        case empty
        case categorySamples
        case singleCategory_Groceries
    }
    
    private static let envKey_TestCategories: String = "TransactionCategoryRepo.envKey_TestCategories"
    
    public static func test(using testCategories: TestCategories = .categorySamples, in environment: inout [String:String]) {
        environment[MockTransactionCategoryRepo.envKey_TestCategories] = testCategories.rawValue
    }
    
    private static func getTestCategories() -> [Transaction.Category]? {
        if let testCategories = TestCategories(rawValue: ProcessInfo.processInfo.environment[Self.envKey_TestCategories] ?? "") {
            switch testCategories {
            case .empty:
                return []
            case .categorySamples:
                return Transaction.Category.samples
            case .singleCategory_Groceries:
                return [ .sampleGroceries ]
            }
        }
        return nil
    }
    
    public static func getTestInstance() -> MockTransactionCategoryRepo? {
        if let testCategories = Self.getTestCategories() {
            return .init(initialCategories: testCategories)
        }
        return nil
    }
}
