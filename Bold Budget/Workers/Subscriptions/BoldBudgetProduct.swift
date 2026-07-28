//
//  BoldBudgetProduct.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/27/26.
//
//  The single source of truth for the App Store products that grant Bold Budget+. Two are
//  auto-renewable subscriptions in one group; the third is a non-consumable lifetime unlock,
//  which is why entitlement checks key off the product id rather than the subscription group
//  (a non-consumable has no `subscriptionGroupID`).
//

import Foundation

enum BoldBudgetProduct {

    /// The auto-renewable subscription group holding the monthly and yearly products.
    static let subscriptionGroupId = "21548808"

    static let monthlyId = "boldBudgetPlusMonthly"
    static let yearlyId = "boldBudgetPlusYearly"
    static let lifetimeId = "com.jasonsapps.boldbudget.Lifetime"

    /// Every product that grants Bold Budget+, in the order the paywall lists them.
    static let allIds: [String] = [yearlyId, monthlyId, lifetimeId]

    /// The renewing products only. Lifetime is deliberately excluded — it never expires and must
    /// not be run through subscription expiry logic.
    static let subscriptionIds: [String] = [monthlyId, yearlyId]

    static func grantsPlus(_ productId: String) -> Bool {
        allIds.contains(productId)
    }

    static func isLifetime(_ productId: String) -> Bool {
        productId == lifetimeId
    }
}
