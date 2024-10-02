//
//  TransactionCategoryProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import Combine
import Foundation

class TransactionCategoryProvider {
    
    private static let envKey_useMocks: String = "TransactionCategoryProvider.envKey_useMocks"
    
    public static func set(useMocks: Bool = true, in environment: inout [String:String]) {
        environment[TransactionCategoryProvider.envKey_useMocks] = String(useMocks)
    }
    
    private static func shouldUseMocks() -> Bool {
        if let useMocks = ProcessInfo.processInfo.environment[Self.envKey_useMocks] {
            return Bool(useMocks) ?? false
        }
        return false
    }
    
    static var instance: TransactionCategoryProvider? = nil
    static func getInstance() -> TransactionCategoryProvider {
        if instance == nil {
            if Self.shouldUseMocks() {
                instance = .init(
                    initialValue: Transaction.Category.samples
                )
            } else {
                //TODO: Get real categories
                instance = .init(
                    initialValue: []
                )
            }
        }
        
        return instance!
    }
    
    private var categoriesSubject: CurrentValueSubject<[Transaction.Category],Never> = .init([])
    
    public var categoriesPublisher: AnyPublisher<[Transaction.Category],Never> {
        categoriesSubject.eraseToAnyPublisher()
    }
    
    public var categories: [Transaction.Category] { categoriesSubject.value }
    
    init(
        initialValue: [Transaction.Category]
    ) {
        categoriesSubject.send(Transaction.Category.samples)
    }
}
