//
//  TransactionLedger.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Combine
import Foundation

protocol TransactionSaver {
    func save(transaction: Transaction) throws
}

protocol TransactionDeleter {
    func delete(transaction: Transaction) throws
}

class TransactionLedger {
    
    static var instance: TransactionLedger? = nil
    static func getInstance() -> TransactionLedger {
        if instance == nil {
            if let testInstance = getTestInstance() {
                instance = testInstance
            } else {
                instance = getDefaultInstance()
            }
        }
        
        return instance!
    }
    
    private static func getDefaultInstance() -> TransactionLedger {
        let cache = TransactionsCache(
            categoryRepo: TransactionCategoryRepo.getInstance()
        )
        return .init(
            getTransactions: { cache.transactions },
            addTransaction: { try cache.add(transaction: $0) },
            removeTransaction: { try cache.remove(transaction: $0) }
        )
    }
    
    private let getTransactions: () -> [Transaction]
    private let addTransaction: (Transaction) throws -> ()
    private let removeTransaction: (Transaction) throws -> ()
    private let transactionsSubject: CurrentValueSubject<[Transaction],Never> = .init([])

    init(
        getTransactions: @escaping () -> [Transaction],
        addTransaction: @escaping (Transaction) throws -> (),
        removeTransaction: @escaping (Transaction) throws -> ()
    ) {
        self.getTransactions = getTransactions
        self.addTransaction = addTransaction
        self.removeTransaction = removeTransaction
        transactionsSubject.send(getTransactions())
    }

    public var transactionPublisher: AnyPublisher<[Transaction],Never> {
        transactionsSubject.eraseToAnyPublisher()
    }
    
    public var transactions: [Transaction] { transactionsSubject.value }
    
    func save(transaction: Transaction) throws {
        do {
            try addTransaction(transaction)
            transactionsSubject.send(getTransactions())
        } catch {
            print("Failed to add transaction: \(error.localizedDescription)")
            throw error
        }
    }
    
    func delete(transaction: Transaction) throws {
        do {
            try removeTransaction(transaction)
            transactionsSubject.send(getTransactions())
        } catch {
            print("Failed to remove transaction: \(error.localizedDescription)")
            throw error
        }
    }
}

extension TransactionLedger: TransactionProvider {}

extension TransactionLedger: TransactionSaver {}

extension TransactionLedger: TransactionDeleter {}

extension TransactionLedger {
    public enum TestTransactions: String, RawRepresentable {
        case empty
        case transactionSamples
        case screenshotSamples
    }
    
    private static let envKey_TestTransactions: String = "TransactionLedger.envKey_TestTransactions"
    
    public static func test(using testTransactions: TestTransactions = .transactionSamples, in environment: inout [String:String]) {
        environment[TransactionLedger.envKey_TestTransactions] = testTransactions.rawValue
    }
    
    private static func getTestTransactions() -> [Transaction]? {
        if let testTransactions = TestTransactions(rawValue: ProcessInfo.processInfo.environment[Self.envKey_TestTransactions] ?? "") {
            switch testTransactions {
            case .empty:
                return []
            case .transactionSamples:
                return Transaction.samples
            case .screenshotSamples:
                return Transaction.screenshotSamples
            }
        }
        return nil
    }
    
    private static func getTestInstance() -> TransactionLedger? {
        if var testTransactions = getTestTransactions() {
            return .init(
                getTransactions: { testTransactions },
                addTransaction: { testTransactions = testTransactions + [$0] },
                removeTransaction: { transaction in testTransactions.removeAll { $0.id == transaction.id } }
            )
        }
        return nil
    }
}
