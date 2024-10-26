//
//  TransactionCategoryRepo.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import Combine
import Foundation

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
        //TODO: Get real categories from cache and from Firebase
        var initial = Transaction.Category.samples
        
        return .init(
            initialCategories: initial,
            insertCategory: { newTransaction in initial = initial + [newTransaction] },
            updateCategory: { updatedTransaction in initial = initial.filter { $0.id != updatedTransaction.id } + [updatedTransaction] }
        )
    }
    
    private let insertCategory: (Transaction.Category) -> ()
    private let updateCategory: (Transaction.Category) -> ()
    private let categoriesSubject: CurrentValueSubject<[Transaction.Category],Never> = .init([])

    init(
        initialCategories: [Transaction.Category],
        insertCategory: @escaping (Transaction.Category) -> (),
        updateCategory: @escaping (Transaction.Category) -> ()
    ) {
        self.insertCategory = insertCategory
        self.updateCategory = updateCategory
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
        updateCategory(category)
        let categories = categories.filter { $0.id != category.id }
        categoriesSubject.send(categories) // Ensures updates if receivers depend on a change of Category.id
        categoriesSubject.send(categories + [category])
    }
    
    private func insert(category: Transaction.Category) {
        insertCategory(category)
        categoriesSubject.send(categoriesSubject.value + [category])
    }
}

extension TransactionCategoryRepo {
    public enum TestCategories: String, RawRepresentable {
        case empty
        case categorySamples
        case singleCategory_Groceries
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
            case .singleCategory_Groceries:
                return [ .sampleGroceries ]
            }
        }
        return nil
    }
    
    private static func getTestInstance() -> TransactionCategoryRepo? {
        if var testCategories = Self.getTestCategories() {
            return .init(
                initialCategories: testCategories,
                insertCategory: { testCategories = testCategories + [$0] },
                updateCategory: { updatedTransaction in testCategories = testCategories.filter { $0.id != updatedTransaction.id } + [updatedTransaction] }
            )
        }
        return nil
    }
}
