//
//  Transaction.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation

struct Transaction: Identifiable {

    /// What the transaction does to net worth.
    ///
    /// `expense` / `income` move money in or out and are also distinguished by their
    /// category's kind (the historical source of truth). `transfer` moves money between two
    /// accounts and is net-worth-neutral — it carries no spending category.
    enum Kind: String, Codable, CaseIterable {
        case expense
        case income
        case transfer

        var name: String {
            switch self {
            case .expense: String(localized: "Expense")
            case .income: String(localized: "Income")
            case .transfer: String(localized: "Transfer")
            }
        }
    }

    let id: Id
    let title: Transaction.Title?
    let amount: Money
    let date: SimpleDate
    let categoryId: Transaction.Category.Id
    let location: Transaction.Location?
    let tags: Set<Transaction.Tag>
    let kind: Kind
    /// The account affected by an `expense` / `income`. Optional: legacy rows are account-less.
    let accountId: Account.Id?
    /// The account money leaves, for a `transfer`.
    let fromAccountId: Account.Id?
    /// The account money lands in, for a `transfer`.
    let toAccountId: Account.Id?

    init(
        id: Id,
        title: Transaction.Title? = nil,
        amount: Money,
        date: SimpleDate,
        categoryId: Transaction.Category.Id,
        location: Transaction.Location? = nil,
        tags: Set<Transaction.Tag> = [],
        kind: Kind = .expense,
        accountId: Account.Id? = nil,
        fromAccountId: Account.Id? = nil,
        toAccountId: Account.Id? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.categoryId = categoryId
        self.location = location
        self.tags = tags
        self.kind = kind
        self.accountId = accountId
        self.fromAccountId = fromAccountId
        self.toAccountId = toAccountId
    }

    var isTransfer: Bool { kind == .transfer }
}

extension Transaction {
    typealias Id = UUID
}

extension Transaction {
    func with(categoryId: Transaction.Category.Id) -> Transaction {
        .init(
            id: id,
            title: title,
            amount: amount,
            date: date,
            categoryId: categoryId,
            location: location,
            tags: tags,
            kind: kind,
            accountId: accountId,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId
        )
    }

    func with(kind: Kind) -> Transaction {
        .init(
            id: id,
            title: title,
            amount: amount,
            date: date,
            categoryId: categoryId,
            location: location,
            tags: tags,
            kind: kind,
            accountId: accountId,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId
        )
    }
}

extension Transaction: Equatable { }

extension Transaction: Hashable { }

extension Transaction {
    static var sampleRandomBasic: Transaction {
        .init(
            id: Id(),
            title: .sample,
            amount: .sampleRandom,
            date: .now,
            categoryId: Category.samples[.random(in: 0..<Category.samples.count)].id,
            location: .sample
        )
    }
    
    static var taggedSample: Transaction {
        .init(
            id: Id(),
            amount: Money(10)!,
            date: .now,
            categoryId: Transaction.Category.sampleGroceries.id,
            tags: [.sample]
        )
    }
    
    static var samples: [Transaction] {
        (0...100).map { _ in Transaction.sampleRandomBasic }
    }
    
    static var samplesOnlyInGroceriesCategory: [Transaction] {
        samples.map { _ in
            let t = Transaction.sampleRandomBasic
            return .init(
                id: t.id,
                title: t.title,
                amount: t.amount,
                date: t.date,
                categoryId: Transaction.Category.sampleGroceries.id,
                location: t.location,
                tags: t.tags
            )
        }
    }
    
    static let screenshotSamples: [Transaction] = [
        .init(
            id: Id(),
            title: .init("Movie Tickets")!,
            amount: .init(47.52)!,
            date: .now,
            categoryId: Transaction.Category.sampleEntertainment.id,
            location: .init("Redmond, WA")
        ),
        .init(
            id: Id(),
            title: .init("Walmart")!,
            amount: .init(87.63)!,
            date: .now,
            categoryId: Transaction.Category.sampleGroceries.id,
            location: .init("Seattle, WA")
        ),
        .init(
            id: Id(),
            title: .init("Rent"),
            amount: .init(750)!,
            date: .now,
            categoryId: Transaction.Category.sampleHousing.id
        ),
        .init(
            id: Id(),
            title: .init("Paycheck")!,
            amount: .init(1084.62)!,
            date: .now,
            categoryId: Transaction.Category.samplePaycheck.id
        ),
        .init(
            id: Id(),
            title: .init("Gas"),
            amount: .init(57.30)!,
            date: .now,
            categoryId: Transaction.Category.sampleVehicle.id,
            location: .init("Redmond, WA")
        ),
        .init(
            id: Id(),
            title: .init("Walmart")!,
            amount: .init(65.24)!,
            date: .startOfMonth(containing: .now),
            categoryId: Transaction.Category.sampleGroceries.id,
            location: .init("Seattle, WA")
        ),
    ]
}
