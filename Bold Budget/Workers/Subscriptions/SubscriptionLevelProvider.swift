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

    /// Whether this Apple ID has *ever* paid for Bold Budget+, including subscriptions that have
    /// since lapsed. `FeatureGate` uses it to refuse grandfathering to a former subscriber — see
    /// `FeatureGate.noteExistingUsage`.
    var hasEverPurchasedPlus: Bool { get }
    var hasEverPurchasedPlusPublisher: Published<Bool>.Publisher { get }

    func handle(transactionUpdate verificationResult: VerificationResult<StoreKit.Transaction>)
    func set(subscriptionLevel: SubscriptionLevel)

    /// Re-derives the level from StoreKit's current entitlements. Called after a restore.
    func refreshEntitlements()
}

class MockSubscriptionLevelProvider: SubscriptionLevelProvider {

    let subscriptionGroupId = BoldBudgetProduct.subscriptionGroupId
    @Published private(set) var subscriptionLevel: SubscriptionLevel
    var subscriptionLevelPublisher: Published<SubscriptionLevel>.Publisher { $subscriptionLevel }

    @Published private(set) var hasEverPurchasedPlus: Bool
    var hasEverPurchasedPlusPublisher: Published<Bool>.Publisher { $hasEverPurchasedPlus }

    init(level: SubscriptionLevel, hasEverPurchasedPlus: Bool = false) {
        subscriptionLevel = level
        self.hasEverPurchasedPlus = hasEverPurchasedPlus || level == .boldBudgetPlus
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
        if subscriptionLevel == .boldBudgetPlus { hasEverPurchasedPlus = true }
    }

    func refreshEntitlements() {}
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
    private let hasEverPurchasedPlusKey = "hasEverPurchasedPlusKey"

    public let subscriptionGroupId = BoldBudgetProduct.subscriptionGroupId

    private var updates: Task<Void, Never>? = nil

    @Published private(set) var subscriptionLevel: SubscriptionLevel = .none
    var subscriptionLevelPublisher: Published<SubscriptionLevel>.Publisher { $subscriptionLevel }

    @Published private(set) var hasEverPurchasedPlus: Bool = false
    var hasEverPurchasedPlusPublisher: Published<Bool>.Publisher { $hasEverPurchasedPlus }

    public static let instance: StoreKitSubscriptionLevelProvider = {
        .init()
    }()

    private init() {
        subscriptionLevel = SubscriptionLevel(rawValue: UserDefaults.standard.string(forKey: subscriptionLevelKey) ?? "") ?? .none
        hasEverPurchasedPlus = UserDefaults.standard.bool(forKey: hasEverPurchasedPlusKey)
        checkSubscriptionStatus()
        checkPurchaseHistory()
        updates = updatesListenerTask()
    }

    private func updatesListenerTask() -> Task<Void, Never> {
        Task(priority: .background) {
            for await verificationResult in StoreKit.Transaction.updates {
                handle(transactionUpdate: verificationResult)
            }
        }
    }

    /// True when a transaction entitles the user to Bold Budget+. Keyed off the product id so the
    /// lifetime non-consumable counts — it has no `subscriptionGroupID`. The group is still
    /// accepted so a future subscription product works before this file learns its id.
    private func grantsPlus(_ transaction: StoreKit.Transaction) -> Bool {
        BoldBudgetProduct.grantsPlus(transaction.productID)
            || transaction.subscriptionGroupID == subscriptionGroupId
    }

    func refreshEntitlements() {
        checkSubscriptionStatus()
        checkPurchaseHistory()
    }

    func checkSubscriptionStatus() {
        Task(priority: .userInitiated) {
            var foundTransaction = false

            for await verificationResult in StoreKit.Transaction.currentEntitlements {
                if case .verified(let transaction) = verificationResult,
                   grantsPlus(transaction)
                {
                    print("StoreKitSubscriptionLevelProvider; found current entitlement \(transaction.productID)")
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

    /// Records whether this Apple ID has ever paid, including lapsed subscriptions. `Transaction.all`
    /// (unlike `currentEntitlements`) keeps expired subscription transactions, which is exactly what
    /// distinguishes a never-paid legacy user from a former subscriber on a fresh install.
    private func checkPurchaseHistory() {
        guard !hasEverPurchasedPlus else { return }

        Task(priority: .background) {
            for await verificationResult in StoreKit.Transaction.all {
                guard case .verified(let transaction) = verificationResult, grantsPlus(transaction) else { continue }
                setHasEverPurchasedPlus()
                return
            }
        }
    }

    func handle(transactionUpdate verificationResult: VerificationResult<StoreKit.Transaction>) {
        print("StoreKitSubscriptionLevelProvider; handle(updatedTransaction:)")
        guard case .verified(let transaction) = verificationResult else {
            // Ignore unverified transactions.
            return
        }
        guard grantsPlus(transaction) else {
            // Ignore transactions we don't know how to handle.
            return
        }

        setHasEverPurchasedPlus()

        if let _ = transaction.revocationDate {
            // Access to this product was revoked (refund, family sharing removal). Another product
            // may still entitle them — a refunded subscription doesn't undo a lifetime unlock — so
            // re-derive the level from current entitlements instead of assuming `.none`.
            checkSubscriptionStatus()
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

    private func setHasEverPurchasedPlus() {
        guard !hasEverPurchasedPlus else { return }
        RunLoop.main.perform { self.hasEverPurchasedPlus = true }
        UserDefaults.standard.set(true, forKey: hasEverPurchasedPlusKey)
    }
}
