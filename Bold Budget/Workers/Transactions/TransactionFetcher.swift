//
//  TransactionFetcher.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import Foundation
import Combine

protocol TransactionFetcher {
    func fetchTransactions(in budget: BudgetInfo) async throws -> [Transaction]
}

class MockTransactionFetcher: TransactionFetcher {
    
    var transactions: [Transaction] = []
    var error: Error? = nil
    
    func fetchTransactions(in budget: BudgetInfo) async throws -> [Transaction] {
        if let error = error {
            throw error
        }
        return transactions
    }
}

extension MockTransactionFetcher {
    
    public enum TestCategory: String, RawRepresentable {
        case empty
        case samples
        case taggedSample
        case screenshotSamples
        case error
    }
    
    private static let envKey_TestCategory: String = "MockTransactionSaver.envKey_TestCategory"
    
    public static func test(using category: TestCategory, in environment: inout [String:String]) {
        environment[envKey_TestCategory] = String(describing: category)
    }
    
    static func getTestInstance() -> MockTransactionFetcher? {
        guard let categoryString = ProcessInfo.processInfo.environment[envKey_TestCategory] else { return nil }
        guard let category = TestCategory(rawValue: categoryString) else { return nil }
        
        let mock = MockTransactionFetcher()
        switch category {
        case .empty:
            mock.transactions = []
            break
        case .samples:
            mock.transactions = Transaction.samples
            break
        case .taggedSample:
            mock.transactions = [Transaction.taggedSample]
            break
        case .screenshotSamples:
            mock.transactions = Transaction.screenshotSamples
            break
        case .error:
            mock.error = TextError("MockTransactionFetcher.TestError")
        }
        return mock
    }
}
