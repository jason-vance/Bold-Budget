//
//  FirebaseTransactionDoc.swift
//  Bold Budget
//
//  Created by Jason Vance on 11/28/24.
//

import Foundation
import FirebaseFirestore

struct FirebaseTransactionDoc: Codable {
    
    @DocumentID var id: String?
    var title: String?
    var amount: Double?
    var intDate: Int?
    var categoryId: String?
    var location: String?
    var tags: [String]?
    var kind: String?
    var accountId: String?
    var fromAccountId: String?
    var toAccountId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case amount
        case intDate
        case categoryId
        case location
        case tags
        case kind
        case accountId
        case fromAccountId
        case toAccountId
    }

    static func from(_ transaction: Transaction) -> FirebaseTransactionDoc {
        FirebaseTransactionDoc(
            id: transaction.id.uuidString,
            title: transaction.title?.value,
            amount: transaction.amount.amount,
            intDate: Int(transaction.date.rawValue),
            categoryId: transaction.categoryId.uuidString,
            location: transaction.location?.value,
            tags: transaction.tags.map { $0.value },
            kind: transaction.kind.rawValue,
            accountId: transaction.accountId?.uuidString,
            fromAccountId: transaction.fromAccountId?.uuidString,
            toAccountId: transaction.toAccountId?.uuidString
        )
    }

    func toTransaction() -> Transaction? {
        guard let id = Transaction.Id(uuidString: id ?? "") else { return nil }
        let title = Transaction.Title(title)
        guard let amount = Money(amount) else { return nil }
        guard let intDate = intDate else { return nil }
        guard let date = SimpleDate(rawValue: UInt32(intDate)) else { return nil }
        guard let categoryId = Transaction.Category.Id(uuidString: categoryId ?? "") else { return nil }
        let location = Transaction.Location(location)
        let tags = Set((tags ?? []).compactMap { Transaction.Tag($0) })
        // Legacy rows have no `kind` — they are never transfers, so `.expense` is a safe default
        // (income vs. expense stays category-derived for non-transfers).
        let kind = Transaction.Kind(rawValue: kind ?? "") ?? .expense

        return .init(
            id: id,
            title: title,
            amount: amount,
            date: date,
            categoryId: categoryId,
            location: location,
            tags: tags,
            kind: kind,
            accountId: Account.Id(uuidString: accountId ?? ""),
            fromAccountId: Account.Id(uuidString: fromAccountId ?? ""),
            toAccountId: Account.Id(uuidString: toAccountId ?? "")
        )
    }
}
