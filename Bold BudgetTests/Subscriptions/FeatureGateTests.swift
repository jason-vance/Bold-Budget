//
//  FeatureGateTests.swift
//  Bold BudgetTests
//
//  Created by Jason Vance on 7/27/26.
//

import Testing
import Foundation

@MainActor
struct FeatureGateTests {

    /// Each gate gets its own defaults suite so a legacy grant in one test can't leak into another,
    /// or into the developer's own app state.
    private func makeGate(
        level: SubscriptionLevel = .none,
        hasEverPurchasedPlus: Bool = false
    ) -> FeatureGate {
        FeatureGate(
            subscriptionLevelProvider: MockSubscriptionLevelProvider(
                level: level,
                hasEverPurchasedPlus: hasEverPurchasedPlus
            ),
            defaults: UserDefaults(suiteName: "FeatureGateTests.\(UUID().uuidString)")!
        )
    }

    // MARK: - Free limits

    @Test func freeUserCanAddAccountsUpToTheLimit() {
        let gate = makeGate()

        #expect(gate.canAddAccount(currentCount: 0))
        #expect(gate.canAddAccount(currentCount: FeatureGate.freeAccountLimit - 1))
        #expect(!gate.canAddAccount(currentCount: FeatureGate.freeAccountLimit))
    }

    @Test func freeUserCanOnlyKeepOneBudget() {
        let gate = makeGate()

        #expect(gate.canAddBudget(currentCount: 0))
        #expect(!gate.canAddBudget(currentCount: 1))
    }

    @Test func plusUserHasNoLimits() {
        let gate = makeGate(level: .boldBudgetPlus)

        #expect(gate.canAddAccount(currentCount: 99))
        #expect(gate.canAddBudget(currentCount: 99))
        #expect(gate.canShareBudget)
        #expect(gate.canSeeNetWorthHistory)
        #expect(gate.canExportTransactions)
        #expect(!gate.showsAds)
    }

    @Test func freeUserIsGatedOutOfTheSharedAndHistoricalFeatures() {
        let gate = makeGate()

        #expect(!gate.canShareBudget)
        #expect(!gate.canSeeNetWorthHistory)
        #expect(!gate.canExportTransactions)
        #expect(gate.showsAds)
    }

    // MARK: - Grandfathering

    @Test func usageAboveTheAccountLimitGrantsLegacyAccess() {
        let gate = makeGate()

        gate.noteExistingUsage(accountCount: FeatureGate.freeAccountLimit + 1)

        #expect(gate.hasLegacyAccess)
        #expect(gate.isUnlocked)
        #expect(gate.canAddAccount(currentCount: 99))
        #expect(gate.canSeeNetWorthHistory)
    }

    @Test func anAlreadySharedBudgetGrantsLegacyAccess() {
        let gate = makeGate()

        gate.noteExistingUsage(isSharedBudget: true)

        #expect(gate.hasLegacyAccess)
        #expect(gate.canShareBudget)
    }

    @Test func usageWithinTheLimitsGrantsNothing() {
        let gate = makeGate()

        gate.noteExistingUsage(accountCount: FeatureGate.freeAccountLimit, budgetCount: 1, isSharedBudget: false)

        #expect(!gate.hasLegacyAccess)
    }

    /// The whole reason `hasEverPurchasedPlus` exists: otherwise someone could subscribe for one
    /// month, build up ten accounts, cancel, and keep the paid feature set for free.
    @Test func aLapsedSubscriberIsNotGrandfathered() {
        let gate = makeGate(level: .none, hasEverPurchasedPlus: true)

        gate.noteExistingUsage(accountCount: 10, budgetCount: 5, isSharedBudget: true)

        #expect(!gate.hasLegacyAccess)
        #expect(!gate.canAddAccount(currentCount: 10))
    }

    @Test func grandfatheredUsersStillSeeAds() {
        let gate = makeGate()

        gate.noteExistingUsage(accountCount: 10)

        #expect(gate.isUnlocked)
        #expect(gate.showsAds, "Legacy users kept their features, not an ad-free app they never had")
        #expect(!gate.canExportTransactions, "CSV export shipped with monetization; there's nothing to grandfather")
    }

    @Test func legacyAccessSurvivesARelaunch() {
        let suiteName = "FeatureGateTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let firstLaunch = FeatureGate(
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .none),
            defaults: defaults
        )
        firstLaunch.noteExistingUsage(accountCount: 8)
        #expect(firstLaunch.hasLegacyAccess)

        let secondLaunch = FeatureGate(
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .none),
            defaults: defaults
        )
        #expect(secondLaunch.hasLegacyAccess)
    }

    @Test func subscribingIsReflectedByTheGate() async throws {
        let provider = MockSubscriptionLevelProvider(level: .none)
        let gate = FeatureGate(
            subscriptionLevelProvider: provider,
            defaults: UserDefaults(suiteName: "FeatureGateTests.\(UUID().uuidString)")!
        )
        #expect(!gate.isPlus)

        provider.set(subscriptionLevel: .boldBudgetPlus)
        // The gate observes the provider through a main-run-loop-scheduled sink.
        try await Task.sleep(for: .milliseconds(100))

        #expect(gate.isPlus)
        #expect(!gate.showsAds)
    }
}
