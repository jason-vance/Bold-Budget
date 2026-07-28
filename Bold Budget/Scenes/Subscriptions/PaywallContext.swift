//
//  PaywallContext.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/27/26.
//
//  Why the paywall opened. A user who just tapped "Add Account" for the fourth time should be met
//  with a headline about accounts, not a generic upsell — the specific ask is what converts.
//

import Foundation

enum PaywallContext {
    case accounts
    case netWorthHistory
    case sharing
    case budgets
    case export
    case general

    var title: String {
        switch self {
        case .accounts: String(localized: "Track every account")
        case .netWorthHistory: String(localized: "See where you're heading")
        case .sharing: String(localized: "Budget together")
        case .budgets: String(localized: "More than one budget")
        case .export: String(localized: "Take your data with you")
        case .general: String(localized: "Bold Budget+")
        }
    }

    var subtitle: String {
        switch self {
        case .accounts:
            String(localized: "Free budgets include \(FeatureGate.freeAccountLimit) accounts. Bold Budget+ removes the limit, so your whole financial picture fits in one place.")
        case .netWorthHistory:
            String(localized: "Your net worth today is always free. Bold Budget+ charts how it has moved over time.")
        case .sharing:
            String(localized: "Invite your partner, family, or roommates to a shared budget with Bold Budget+. They don't need their own subscription.")
        case .budgets:
            String(localized: "Free accounts keep one budget. Bold Budget+ lets you run as many as you need.")
        case .export:
            String(localized: "Export every transaction to CSV with Bold Budget+ — your data, in a file you own.")
        case .general:
            String(localized: "Unlock the full picture of your money.")
        }
    }

    var sfSymbol: String {
        switch self {
        case .accounts: "building.columns"
        case .netWorthHistory: "chart.line.uptrend.xyaxis"
        case .sharing: "person.2"
        case .budgets: "square.stack.3d.up"
        case .export: "square.and.arrow.up"
        case .general: "sparkles"
        }
    }
}
