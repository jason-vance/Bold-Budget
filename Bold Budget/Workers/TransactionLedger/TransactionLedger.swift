//
//  TransactionLedger.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Combine
import Foundation

protocol TransactionDeleter {
    func delete(transaction: Transaction)
}

protocol TransactionTagProvider {
    var tagsPublisher: AnyPublisher<Set<Transaction.Tag>,Never> { get }
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
        //TODO: Get real transactions from cache and from Firebase
        var initial = Transaction.samples
        
        return .init(
            initialTransactions: initial,
            insertTransaction: { initial = initial + [$0] },
            deleteTransaction: { transactionToDelete in initial = initial.filter { transaction in transaction.id != transactionToDelete.id } }
        )
    }
    
    private let insertTransaction: (Transaction) -> ()
    private let deleteTransaction: (Transaction) -> ()
    private let transactionsSubject: CurrentValueSubject<[Transaction],Never> = .init([])

    init(
        initialTransactions: [Transaction],
        insertTransaction: @escaping (Transaction) -> (),
        deleteTransaction: @escaping (Transaction) -> ()
    ) {
        self.insertTransaction = insertTransaction
        self.deleteTransaction = deleteTransaction
        transactionsSubject.send(initialTransactions)
    }

    public var transactionPublisher: AnyPublisher<[Transaction],Never> {
        transactionsSubject.eraseToAnyPublisher()
    }
    
    public var transactions: [Transaction] { transactionsSubject.value }
    
    func save(transaction: Transaction, to budget: Budget) async throws {
        insertTransaction(transaction)
        transactionsSubject.send(transactionsSubject.value + [transaction])
    }

    func delete(transaction: Transaction) {
        deleteTransaction(transaction)
        transactionsSubject.send(transactionsSubject.value.filter { $0.id != transaction.id })
    }
}

extension TransactionLedger: TransactionProvider {}

extension TransactionLedger: TransactionSaver {}

extension TransactionLedger: TransactionDeleter {}

extension TransactionLedger: TransactionTagProvider {
    var tagsPublisher: AnyPublisher<Set<Transaction.Tag>, Never> {
        transactionPublisher
            .map { $0.reduce(Set<Transaction.Tag>()) { tags, transaction in tags.union(transaction.tags) } }
            .eraseToAnyPublisher()
    }
}

extension TransactionLedger {
    public enum TestTransactions: String, RawRepresentable {
        case empty
        case transactionSamples
        case screenshotSamples
        case onlyGroceryTransactions
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
            case .onlyGroceryTransactions:
                return Transaction.samplesOnlyInGroceriesCategory
            }
        }
        return nil
    }
    
    private static func getTestInstance() -> TransactionLedger? {
        if var testTransactions = getTestTransactions() {
            return .init(
                initialTransactions: testTransactions,
                insertTransaction: { testTransactions = testTransactions + [$0] },
                deleteTransaction: { transaction in testTransactions.removeAll { $0.id == transaction.id } }
            )
        }
        return nil
    }
}
