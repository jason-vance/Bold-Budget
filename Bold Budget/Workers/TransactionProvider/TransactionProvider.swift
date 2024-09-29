//
//  TransactionProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Combine
import Foundation

class TransactionProvider {
    
    static func getInstance() -> TransactionProvider { .init() }
    
    private var transactions: CurrentValueSubject<[Transaction],Never> = .init([])
    
    public var transactionPublisher: AnyPublisher<[Transaction],Never> {
        transactions.eraseToAnyPublisher()
    }
    
    init() {
        //TODO: Get real transactions
        transactions.send((0...100).map { _ in Transaction.sampleRandomBasic })
    }
}
