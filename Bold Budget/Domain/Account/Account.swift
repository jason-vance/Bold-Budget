//
//  Account.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/21/26.
//

import Foundation

/// A place money lives: a bank account, an investment, a loan, cash, etc.
///
/// Accounts are the backbone of net-worth tracking. Each one is either an asset or a liability
/// (derived from its `kind`) and is tracked either as a running `ledger` or as periodic manual
/// `snapshot`s — the latter mirrors how retirement/brokerage balances get updated once a month.
struct Account: Identifiable {

    /// Whether an account adds to or subtracts from net worth.
    enum Class: String, Codable, CaseIterable {
        case asset
        case liability

        var name: String {
            switch self {
            case .asset: String(localized: "Asset")
            case .liability: String(localized: "Liability")
            }
        }

        var pluralName: String {
            switch self {
            case .asset: String(localized: "Assets")
            case .liability: String(localized: "Liabilities")
            }
        }
    }

    /// The specific flavor of account. Its `accountClass` determines asset vs. liability.
    enum Kind: String, Codable, CaseIterable {
        // Assets
        case checking
        case savings
        case hysa
        case cash
        case brokerage
        case retirement
        case otherAsset
        // Liabilities
        case creditCard
        case loan
        case mortgage
        case otherLiability

        var accountClass: Class {
            switch self {
            case .checking, .savings, .hysa, .cash, .brokerage, .retirement, .otherAsset:
                return .asset
            case .creditCard, .loan, .mortgage, .otherLiability:
                return .liability
            }
        }

        var name: String {
            switch self {
            case .checking: String(localized: "Checking")
            case .savings: String(localized: "Savings")
            case .hysa: String(localized: "High-Yield Savings")
            case .cash: String(localized: "Cash")
            case .brokerage: String(localized: "Brokerage")
            case .retirement: String(localized: "Retirement")
            case .otherAsset: String(localized: "Other Asset")
            case .creditCard: String(localized: "Credit Card")
            case .loan: String(localized: "Loan")
            case .mortgage: String(localized: "Mortgage")
            case .otherLiability: String(localized: "Other Liability")
            }
        }

        var sfSymbol: String {
            switch self {
            case .checking: "building.columns.fill"
            case .savings: "banknote.fill"
            case .hysa: "chart.line.uptrend.xyaxis"
            case .cash: "dollarsign.circle.fill"
            case .brokerage: "chart.bar.fill"
            case .retirement: "figure.walk.motion"
            case .otherAsset: "square.stack.3d.up.fill"
            case .creditCard: "creditcard.fill"
            case .loan: "car.fill"
            case .mortgage: "house.fill"
            case .otherLiability: "arrow.down.circle.fill"
            }
        }

        /// Kinds grouped by class, preserving declaration order, for pickers.
        static func kinds(in accountClass: Class) -> [Kind] {
            allCases.filter { $0.accountClass == accountClass }
        }
    }

    /// How an account's balance is kept up to date.
    enum TrackingMode: String, Codable, CaseIterable {
        /// Balance is adjusted by linked transactions (checking, credit cards).
        case ledger
        /// Balance is set by periodic manual entries (retirement, brokerage).
        case snapshot

        var name: String {
            switch self {
            case .ledger: String(localized: "Transactions")
            case .snapshot: String(localized: "Manual balance")
            }
        }

        var description: String {
            switch self {
            case .ledger: String(localized: "Balance changes as you add transactions.")
            case .snapshot: String(localized: "You enter the balance yourself, whenever it changes.")
            }
        }
    }

    let id: Id
    let name: Name
    let kind: Kind
    let trackingMode: TrackingMode
    /// Current balance as a non-negative magnitude. Sign is implied by `accountClass`.
    let balance: Money
    /// Manual balance history, most useful for `.snapshot` accounts. Kept sorted by date.
    let snapshots: [BalanceSnapshot]
    /// Optional recurring monthly payment, for liabilities (a loan/mortgage/card payment).
    /// This is what a recurring "debt" folds into.
    let monthlyPayment: Money?

    init(
        id: Id,
        name: Name,
        kind: Kind,
        trackingMode: TrackingMode,
        balance: Money,
        snapshots: [BalanceSnapshot] = [],
        monthlyPayment: Money? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.trackingMode = trackingMode
        self.balance = balance
        self.snapshots = snapshots.sorted { $0.date > $1.date }
        self.monthlyPayment = monthlyPayment
    }

    var accountClass: Class { kind.accountClass }

    /// Balance with direction: assets positive, liabilities negative.
    var signedBalance: SignedMoney {
        accountClass == .asset ? .init(balance.amount) : .init(-balance.amount)
    }

    var latestSnapshot: BalanceSnapshot? { snapshots.first }

    /// The most recent balance change, if at least two snapshots exist.
    var latestChange: SignedMoney? {
        guard snapshots.count >= 2 else { return nil }
        return .init(snapshots[0].value.amount - snapshots[1].value.amount)
    }

    /// Returns a copy with a different current balance, leaving snapshots untouched.
    func withBalance(_ balance: Money) -> Account {
        .init(
            id: id,
            name: name,
            kind: kind,
            trackingMode: trackingMode,
            balance: balance,
            snapshots: snapshots,
            monthlyPayment: monthlyPayment
        )
    }

    /// Returns a copy with a cash flow applied to the balance.
    ///
    /// Inflow raises an asset's balance and lowers a liability's (paying it down); outflow does
    /// the reverse. Balances are clamped at zero — reconciliation corrects any drift.
    func applying(cashFlow amount: Money, isInflow: Bool) -> Account {
        let raises = (accountClass == .asset) == isInflow
        let newAmount = max(0, balance.amount + (raises ? amount.amount : -amount.amount))
        return withBalance(Money(newAmount) ?? .zero)
    }

    /// Returns a copy with the snapshot on `date` removed. Current balance is left unchanged.
    func removingSnapshot(on date: SimpleDate) -> Account {
        .init(
            id: id,
            name: name,
            kind: kind,
            trackingMode: trackingMode,
            balance: balance,
            snapshots: snapshots.filter { $0.date != date },
            monthlyPayment: monthlyPayment
        )
    }

    /// Returns a copy with a snapshot recorded for `date` and the balance set to `value`.
    func recordingSnapshot(value: Money, on date: SimpleDate) -> Account {
        var updated = snapshots.filter { $0.date != date }
        updated.append(.init(date: date, value: value))
        return .init(
            id: id,
            name: name,
            kind: kind,
            trackingMode: trackingMode,
            balance: value,
            snapshots: updated,
            monthlyPayment: monthlyPayment
        )
    }
}

extension Account {
    typealias Id = UUID
}

extension Account: Equatable {}
extension Account: Hashable {}

extension Account {

    static let sampleChecking: Account = .init(
        id: Id(),
        name: .init("America First")!,
        kind: .checking,
        trackingMode: .ledger,
        balance: Money(12727)!
    )

    static let sampleRobinhood: Account = .init(
        id: Id(),
        name: .init("Robinhood")!,
        kind: .brokerage,
        trackingMode: .snapshot,
        balance: Money(324870)!,
        snapshots: [
            .init(date: .init(rawValue: 20250201)!, value: Money(338286)!),
            .init(date: .init(rawValue: 20250301)!, value: Money(213622)!),
            .init(date: .init(rawValue: 20250401)!, value: Money(242537)!),
            .init(date: .init(rawValue: 20250501)!, value: Money(291448)!),
            .init(date: .init(rawValue: 20250601)!, value: Money(324870)!),
        ]
    )

    static let sample401k: Account = .init(
        id: Id(),
        name: .init("401k")!,
        kind: .retirement,
        trackingMode: .snapshot,
        balance: Money(218757)!,
        snapshots: [
            .init(date: .init(rawValue: 20250501)!, value: Money(208796)!),
            .init(date: .init(rawValue: 20250601)!, value: Money(218757)!),
        ]
    )

    static let sampleCarLoan: Account = .init(
        id: Id(),
        name: .init("CX-30 Loan")!,
        kind: .loan,
        trackingMode: .snapshot,
        balance: Money(28179)!,
        monthlyPayment: Money(458)!
    )

    static let samples: [Account] = [
        sampleChecking,
        sampleRobinhood,
        sample401k,
        .init(
            id: Id(),
            name: .init("Vanguard IRA")!,
            kind: .retirement,
            trackingMode: .snapshot,
            balance: Money(35716)!
        ),
        .init(
            id: Id(),
            name: .init("Ally HYSA")!,
            kind: .hysa,
            trackingMode: .snapshot,
            balance: Money(83)!
        ),
        sampleCarLoan,
    ]
}

extension Collection where Element == Account {

    var assets: [Account] { filter { $0.accountClass == .asset } }
    var liabilities: [Account] { filter { $0.accountClass == .liability } }

    var totalAssets: Money { assets.reduce(.zero) { $0 + $1.balance } }
    var totalLiabilities: Money { liabilities.reduce(.zero) { $0 + $1.balance } }

    /// Sum of all recurring monthly payments across accounts (loans, mortgages, cards).
    var totalMonthlyPayments: Money {
        reduce(.zero) { $0 + ($1.monthlyPayment ?? .zero) }
    }

    /// Assets minus liabilities. May be negative.
    var netWorth: SignedMoney {
        .init(totalAssets.amount - totalLiabilities.amount)
    }
}
