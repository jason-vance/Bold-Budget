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
                    addTransaction: { transactions = transactions + [$0] }
                )
            } else {
                let cache = TransactionsCache(
                    categoryRepo: TransactionCategoryRepo.getInstance()
                )
                instance = .init(
                    getTransactions: { cache.transactions },
                    addTransaction: { try cache.add(transaction: $0) }
                )
            }
        }
        
        return instance!
    }
    
    private let getTransactions: () -> [Transaction]
    private let addTransaction: (Transaction) throws -> ()
    private let transactionsSubject: CurrentValueSubject<[Transaction],Never> = .init([])

    init(
        getTransactions: @escaping () -> [Transaction],
        addTransaction: @escaping (Transaction) throws -> ()
    ) {
        self.getTransactions = getTransactions
        self.addTransaction = addTransaction
        transactionsSubject.send(getTransactions())
    }

    public var transactionPublisher: AnyPublisher<[Transaction],Never> {
        transactionsSubject.eraseToAnyPublisher()
    }
    
    public var transactions: [Transaction] { transactionsSubject.value }
    
    func save(transaction: Transaction) {
        do {
            try addTransaction(transaction)
            transactionsSubject.send(getTransactions())
        } catch {
            print("Failed to add transaction: \(error.localizedDescription)")
        }
    }
}

extension TransactionLedger: TransactionProvider {}

extension TransactionLedger: TransactionSaver {}
