//
//  TransactionCategoryRepo.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import Combine
import Foundation
import SwiftData

protocol TransactionCategorySaver {
    func insert(category: Transaction.Category)
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
        let context: ModelContext = {
            let context = ModelContext(sharedModelContainer)
            context.autosaveEnabled = true
            return context
        }()
        
        guard let initial = try? context.fetch(FetchDescriptor<Transaction.Category>()) else { fatalError("Could not fetch initial categories") }
        
        return .init(
            initialCategories: initial,
            insertCategory: { context.insert($0) }
        )
    }
    
    private let insertCategory: (Transaction.Category) -> ()
    private let categoriesSubject: CurrentValueSubject<[Transaction.Category],Never> = .init([])

    init(
        initialCategories: [Transaction.Category],
        insertCategory: @escaping (Transaction.Category) -> ()
    ) {
        self.insertCategory = insertCategory
        Task { categoriesSubject.send(initialCategories) }
    }
    
    public var categoriesPublisher: AnyPublisher<[Transaction.Category],Never> {
        categoriesSubject.eraseToAnyPublisher()
    }
    
    public var categories: [Transaction.Category] { categoriesSubject.value }
    
    func insert(category: Transaction.Category) {
        insertCategory(category)
        categoriesSubject.send(categoriesSubject.value + [category])
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
                initialCategories: testCategories,
                insertCategory: { testCategories = testCategories + [$0] }
            )
        }
        return nil
    }
}
