//
//  FeatureGate.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/27/26.
//
//  The one place that answers "may this user do X?". Every Plus check in the UI goes through here
//  rather than comparing `SubscriptionLevel` inline, so the free limits live in a single file.
//
//  Two kinds of access, deliberately not the same thing:
//
//  * `isPlus` — currently paying (or lifetime). Unlocks everything, including perks that never
//    existed before monetization, like ad removal and CSV export.
//  * `isUnlocked` — `isPlus` *or* grandfathered. Everything Bold Budget shipped free before gating
//    stays available to the people who were already using it. They still see ads, because they
//    always did; taking a feature away is what generates one-star reviews, not leaving ads alone.
//

import Combine
import Foundation

@MainActor
final class FeatureGate: ObservableObject {

    /// Accounts a free user may create. Chosen so a simple checking/savings/credit setup never
    /// hits the wall — the gate is meant to catch the full net-worth user, not the casual one.
    static let freeAccountLimit = 3

    /// Budgets a free user may own.
    static let freeBudgetLimit = 1

    private static let legacyAccessKey = "FeatureGate.hasLegacyAccess"

    @Published private(set) var subscriptionLevel: SubscriptionLevel = .none

    /// Set once, permanently, for users who were over a free limit before gating existed.
    @Published private(set) var hasLegacyAccess: Bool

    private let subscriptionLevelProvider: SubscriptionLevelProvider
    private let defaults: UserDefaults
    private var cancellables: Set<AnyCancellable> = []

    init(
        subscriptionLevelProvider: SubscriptionLevelProvider,
        defaults: UserDefaults = .standard
    ) {
        self.subscriptionLevelProvider = subscriptionLevelProvider
        self.defaults = defaults
        self.hasLegacyAccess = defaults.bool(forKey: Self.legacyAccessKey)
        self.subscriptionLevel = subscriptionLevelProvider.subscriptionLevel

        subscriptionLevelProvider.subscriptionLevelPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.subscriptionLevel = $0 }
            .store(in: &cancellables)
    }

    // MARK: - Access

    var isPlus: Bool { subscriptionLevel == .boldBudgetPlus }

    /// Has the full pre-gating feature set, whether by paying or by grandfathering.
    var isUnlocked: Bool { isPlus || hasLegacyAccess }

    // MARK: - Individual gates

    /// Ads are removed only by paying. Grandfathered users kept their features, not their ad-free
    /// experience — they never had one.
    var showsAds: Bool { !isPlus }

    /// The current net worth number is always free; the history chart behind it is the paid part.
    var canSeeNetWorthHistory: Bool { isUnlocked }

    /// Gates *inviting* someone new. Existing members of a shared budget are never removed.
    var canShareBudget: Bool { isUnlocked }

    /// Introduced with monetization, so there is nothing to grandfather.
    var canExportTransactions: Bool { isPlus }

    func canAddAccount(currentCount: Int) -> Bool {
        isUnlocked || currentCount < Self.freeAccountLimit
    }

    func canAddBudget(currentCount: Int) -> Bool {
        isUnlocked || currentCount < Self.freeBudgetLimit
    }

    // MARK: - Grandfathering

    /// Grants permanent legacy access when usage above a free limit is observed.
    ///
    /// A free user can't *get* above a limit once gating is live, so any over-limit usage means the
    /// data predates it — except for a former subscriber who built it up while paying and then
    /// lapsed. `hasEverPurchasedPlus` excludes exactly that case, which is why the check exists
    /// instead of a simpler "audit on first launch" (that would miss budgets the user hasn't
    /// opened yet).
    func noteExistingUsage(
        accountCount: Int? = nil,
        budgetCount: Int? = nil,
        isSharedBudget: Bool = false
    ) {
        guard !hasLegacyAccess, !isPlus, !subscriptionLevelProvider.hasEverPurchasedPlus else { return }

        let isOverALimit = (accountCount ?? 0) > Self.freeAccountLimit
            || (budgetCount ?? 0) > Self.freeBudgetLimit
            || isSharedBudget

        guard isOverALimit else { return }

        print("FeatureGate; granting legacy access")
        hasLegacyAccess = true
        defaults.set(true, forKey: Self.legacyAccessKey)
    }
}

extension FeatureGate {

    /// A throwaway gate for previews and tests. Backed by its own `UserDefaults` suite so a preview
    /// granting legacy access can never write into the real app's state.
    static func stub(level: SubscriptionLevel, hasEverPurchasedPlus: Bool = false) -> FeatureGate {
        let suiteName = "FeatureGate.stub.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        return FeatureGate(
            subscriptionLevelProvider: MockSubscriptionLevelProvider(
                level: level,
                hasEverPurchasedPlus: hasEverPurchasedPlus
            ),
            defaults: defaults
        )
    }

    static var previewPlus: FeatureGate { .stub(level: .boldBudgetPlus) }
    static var previewFree: FeatureGate { .stub(level: .none) }
}
