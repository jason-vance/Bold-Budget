//
//  TransactionLedger.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Combine
import Foundation

protocol TransactionSaver {
    func save(transaction: Transaction)
}

protocol TransactionDeleter {
    func delete(transaction: Transaction) throws
}

class TransactionLedger {
    
    private static let envKey_useMocks: String = "TransactionLedger.envKey_useMocks"
    
    public static func set(useMocks: Bool = true, in environment: inout [String:String]) {
        environment[TransactionLedger.envKey_useMocks] = String(useMocks)
    }
    
    private static func shouldUseMocks() -> Bool {
        if let useMocks = ProcessInfo.processInfo.environment[Self.envKey_useMocks] {
            return Bool(useMocks) ?? false
        }
        return false
    }
    
    static var instance: TransactionLedger? = nil
    static func getInstance() -> TransactionLedger {
        if instance == nil {
            if Self.shouldUseMocks() {
                var transactions = Transaction.samples
                instance = .init(
                    getTransactions: { transactions },
                    addTransaction: { transactions = transactions + [$0] },
                    removeTransaction: { transaction in transactions.removeAll { $0.id == transaction.id } }
                )
            } else {
                let cache = TransactionsCache(
                    categoryRepo: TransactionCategoryRepo.getInstance()
                )
                instance = .init(
                    getTransactions: { cache.transactions },
                    addTransaction: { try cache.add(transaction: $0) },
                    removeTransaction: { try cache.remove(transaction: $0) }
                )
            }
        }
        
        return instance!
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
    
    //TODO: Pass this on to UI somehow
    func save(transaction: Transaction) {
        do {
            try addTransaction(transaction)
            transactionsSubject.send(getTransactions())
        } catch {
            print("Failed to add transaction: \(error.localizedDescription)")
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
