//
//  PlusStore.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/27/26.
//
//  Loads the Bold Budget+ products and drives purchase / restore for the paywall.
//
//  Entitlement state is *not* owned here — `SubscriptionLevelProvider` remains the source of truth
//  and is handed every successful transaction. StoreKit's `Transaction.updates` would deliver the
//  same transaction anyway; handing it over directly just means the UI unlocks immediately rather
//  than a beat later.
//

import Foundation
import StoreKit

@MainActor
final class PlusStore: ObservableObject {

    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    enum PurchaseOutcome: Equatable {
        case purchased
        case cancelled
        /// Ask-to-buy or another out-of-band approval; the transaction may arrive later.
        case pending
    }

    @Published private(set) var loadState: LoadState = .loading
    @Published private(set) var products: [Product] = []
    @Published private(set) var isBusy: Bool = false

    /// Whether this Apple ID can still take the free trial. Introductory offers are once per
    /// subscription group, so the paywall must not promise a trial to someone who used it already.
    @Published private(set) var isEligibleForIntroOffer: Bool = false

    private let subscriptionLevelProvider: SubscriptionLevelProvider

    init(subscriptionLevelProvider: SubscriptionLevelProvider) {
        self.subscriptionLevelProvider = subscriptionLevelProvider
    }

    var monthly: Product? { products.first { $0.id == BoldBudgetProduct.monthlyId } }
    var yearly: Product? { products.first { $0.id == BoldBudgetProduct.yearlyId } }
    var lifetime: Product? { products.first { $0.id == BoldBudgetProduct.lifetimeId } }

    /// What the yearly plan saves against twelve months of the monthly plan, as a whole percent.
    /// Derived from the live prices so it stays honest in every storefront.
    var yearlySavingsPercent: Int? {
        guard let monthly = monthly?.price, let yearly = yearly?.price, monthly > 0 else { return nil }
        let fullPrice = monthly * Decimal(12)
        guard yearly < fullPrice else { return nil }
        let fraction = (fullPrice - yearly) / fullPrice
        return Int((NSDecimalNumber(decimal: fraction * Decimal(100)).doubleValue).rounded())
    }

    /// The yearly price divided into twelve, formatted in the product's own currency — the number
    /// that makes an annual plan legible next to a monthly one.
    func monthlyEquivalent(of product: Product) -> String? {
        guard product.id == BoldBudgetProduct.yearlyId else { return nil }
        return (product.price / 12).formatted(product.priceFormatStyle)
    }

    /// How many times to ask the App Store for the products before giving up, and how long to wait
    /// between tries. A cold StoreKit — a sandbox account on a freshly installed build, which is
    /// exactly what App Review runs — can hand back an empty set on the first call and the full set
    /// a second later, so one attempt is not enough to conclude the products don't exist.
    private static let loadAttempts = 3
    private static let delayBetweenLoadAttempts: Duration = .seconds(2)

    func loadProducts() async {
        loadState = .loading

        for attempt in 1...Self.loadAttempts {
            do {
                let loaded = try await Product.products(for: BoldBudgetProduct.allIds)

                // `Product.products(for:)` silently drops ids it can't resolve rather than throwing,
                // so a missing product looks identical to no products at all. Name the missing ones:
                // on device that means App Store Connect state (Missing Metadata, agreements), and in
                // the simulator it means the scheme's StoreKit configuration file isn't attached.
                let missingIds = BoldBudgetProduct.allIds.filter { id in !loaded.contains { $0.id == id } }
                if !missingIds.isEmpty {
                    print("PlusStore; StoreKit did not return: \(missingIds.joined(separator: ", "))")
                }

                if loaded.isEmpty {
                    print("PlusStore; StoreKit returned no products on attempt \(attempt) of \(Self.loadAttempts)")
                    if attempt < Self.loadAttempts {
                        try? await Task.sleep(for: Self.delayBetweenLoadAttempts)
                        continue
                    }
                    loadState = .failed(String(localized: "Bold Budget+ isn't available right now. Please try again later."))
                    return
                }

                // Present in a deliberate order (yearly, monthly, lifetime) rather than StoreKit's.
                products = BoldBudgetProduct.allIds.compactMap { id in loaded.first { $0.id == id } }

                // Show the plans now. Intro-offer eligibility is a separate round trip that only
                // changes the wording of the trial line; making the prices wait on it would leave a
                // spinner where the products should be if that call is slow to come back.
                loadState = .loaded

                isEligibleForIntroOffer = await Product.SubscriptionInfo.isEligibleForIntroOffer(
                    for: BoldBudgetProduct.subscriptionGroupId
                )
                return
            } catch {
                print("PlusStore; failed to load products on attempt \(attempt) of \(Self.loadAttempts). \(error.localizedDescription)")
                if attempt < Self.loadAttempts {
                    try? await Task.sleep(for: Self.delayBetweenLoadAttempts)
                    continue
                }
                loadState = .failed(String(localized: "Couldn't reach the App Store. Check your connection and try again."))
            }
        }
    }

    @discardableResult
    func purchase(_ product: Product) async throws -> PurchaseOutcome {
        isBusy = true
        defer { isBusy = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            subscriptionLevelProvider.handle(transactionUpdate: verification)
            if case .verified(let transaction) = verification {
                await transaction.finish()
            }
            return .purchased
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .cancelled
        }
    }

    /// Pulls the App Store account's purchases down to this device, then re-derives entitlement.
    /// Returns whether the user ended up with Bold Budget+.
    @discardableResult
    func restorePurchases() async throws -> Bool {
        isBusy = true
        defer { isBusy = false }

        try await AppStore.sync()
        subscriptionLevelProvider.refreshEntitlements()

        for await verificationResult in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = verificationResult else { continue }
            if BoldBudgetProduct.grantsPlus(transaction.productID) { return true }
        }
        return false
    }
}
