//
//  SubscriptionLevelProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/10/24.
//

import Foundation
import StoreKit

enum SubscriptionLevel: String {
    case none
    case boldBudgetPlus
}

protocol SubscriptionLevelProvider {
    var subscriptionGroupId: String { get }
    var subscriptionLevel: SubscriptionLevel { get }
    var subscriptionLevelPublisher: Published<SubscriptionLevel>.Publisher { get }
    
    func handle(transactionUpdate verificationResult: VerificationResult<StoreKit.Transaction>)
    func set(subscriptionLevel: SubscriptionLevel)
}

class MockSubscriptionLevelProvider: SubscriptionLevelProvider {
    
    let subscriptionGroupId = "21548808"
    @Published private(set) var subscriptionLevel: SubscriptionLevel
    var subscriptionLevelPublisher: Published<SubscriptionLevel>.Publisher { $subscriptionLevel }
    
    init(level: SubscriptionLevel) {
        subscriptionLevel = level
    }
    
    func handle(transactionUpdate verificationResult: VerificationResult<StoreKit.Transaction>) {
        print("MockSubscriptionLevelProvider; handle(updatedTransaction:)")
        guard case .verified(let transaction) = verificationResult else { return }

        if let _ = transaction.revocationDate {
            subscriptionLevel = .none
        } else if let expirationDate = transaction.expirationDate,
            expirationDate < Date() {
            return
        } else if transaction.isUpgraded {
            return
        } else {
            subscriptionLevel = .boldBudgetPlus
        }
    }
    
    func set(subscriptionLevel: SubscriptionLevel) {
        self.subscriptionLevel = subscriptionLevel
    }
}

extension MockSubscriptionLevelProvider {
    private static let envKey_TestSubscriptionLevel: String = "MockSubscriptionLevelProvider.envKey_TestSubscriptionLevel"
    
    public static func test(subscriptionLevel: SubscriptionLevel, in environment: inout [String:String]) {
        environment[envKey_TestSubscriptionLevel] = String(describing: subscriptionLevel)
    }
    
    static func getTestInstance() -> MockSubscriptionLevelProvider? {
        guard let subscriptionLevelString = ProcessInfo.processInfo.environment[envKey_TestSubscriptionLevel] else { return nil }
        guard let subscriptionLevel = SubscriptionLevel(rawValue: subscriptionLevelString) else { return nil }
        
        return MockSubscriptionLevelProvider(level: subscriptionLevel)
    }
}

class StoreKitSubscriptionLevelProvider: SubscriptionLevelProvider {
    
    private let subscriptionLevelKey = "subscriptionLevelKey"
    
    public let subscriptionGroupId = "21548808"
    public let boldBudgetPlusMonthlyId = "boldBudgetPlusMonthly"
    public let boldBudgetPlusYearlyId = "boldBudgetPlusYearly"
    private var subscriptions: [String] { [boldBudgetPlusMonthlyId, boldBudgetPlusYearlyId] }
    
    private var updates: Task<Void, Never>? = nil
    
    @Published private(set) var subscriptionLevel: SubscriptionLevel = .none
    var subscriptionLevelPublisher: Published<SubscriptionLevel>.Publisher { $subscriptionLevel }
    
    public static let instance: StoreKitSubscriptionLevelProvider = {
        .init()
    }()
    
    private init() {
        checkSubscriptionStatus()
        updates = updatesListenerTask()
    }
    
    private func updatesListenerTask() -> Task<Void, Never> {
        Task(priority: .background) {
            for await verificationResult in StoreKit.Transaction.updates {
                handle(transactionUpdate: verificationResult)
            }
        }
    }
        
    func checkSubscriptionStatus() {
        subscriptionLevel = SubscriptionLevel(rawValue: UserDefaults.standard.string(forKey: subscriptionLevelKey) ?? "") ?? .none
        
        Task(priority: .userInitiated) {
            var foundTransaction = false
            
            for await verificationResult in StoreKit.Transaction.currentEntitlements {
                if case .verified(let transaction) = verificationResult,
                   subscriptionGroupId == transaction.subscriptionGroupID
                {
                    print("StoreKitSubscriptionLevelProvider; found current entitlement")
                    set(subscriptionLevel: .boldBudgetPlus)
                    foundTransaction = true
                }
            }
            
            if !foundTransaction {
                print("StoreKitSubscriptionLevelProvider; did not find current entitlement")
                set(subscriptionLevel: .none)
            }
        }
    }
    
    func handle(transactionUpdate verificationResult: VerificationResult<StoreKit.Transaction>) {
        print("StoreKitSubscriptionLevelProvider; handle(updatedTransaction:)")
        guard case .verified(let transaction) = verificationResult else {
            // Ignore unverified transactions.
            return
        }
        guard subscriptions.contains(transaction.productID) else {
            // Ignore transactions we don't know how to handle.
            return
        }


        if let _ = transaction.revocationDate {
            // Remove access to the product identified by transaction.productID.
            // Transaction.revocationReason provides details about
            // the revoked transaction.
            set(subscriptionLevel: .none)
        } else if let expirationDate = transaction.expirationDate,
            expirationDate < Date() {
            // Do nothing, this subscription is expired.
            return
        } else if transaction.isUpgraded {
            // Do nothing, there is an active transaction
            // for a higher level of service.
            return
        } else {
            // Provide access to the product identified by
            // transaction.productID.
            set(subscriptionLevel: .boldBudgetPlus)
        }
    }
    
    func set(subscriptionLevel: SubscriptionLevel) {
        RunLoop.main.perform { self.subscriptionLevel = subscriptionLevel }
        UserDefaults.standard.set(subscriptionLevel.rawValue, forKey: subscriptionLevelKey)
    }
}
