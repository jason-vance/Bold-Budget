//
//  TransactionLedger.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Combine
import Foundation

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
                instance = .init(
                    initialValue: (0...100).map { _ in Transaction.sampleRandomBasic }
                )
            } else {
                //TODO: Get real transactions
                instance = .init(
                    initialValue: []
                )
            }
        }
        
        return instance!
    }
    
    private var transactions: CurrentValueSubject<[Transaction],Never> = .init([])
    
    public var transactionPublisher: AnyPublisher<[Transaction],Never> {
        transactions.eraseToAnyPublisher()
    }
    
    init(
        initialValue: [Transaction]
    ) {
        transactions.send(initialValue)
    }
}

extension TransactionLedger: TransactionProvider {}
