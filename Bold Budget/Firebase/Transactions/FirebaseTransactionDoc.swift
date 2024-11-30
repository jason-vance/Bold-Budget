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

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case amount
        case intDate
        case categoryId
        case location
        case tags
    }
    
    static func from(_ transaction: Transaction) -> FirebaseTransactionDoc {
        FirebaseTransactionDoc(
            id: transaction.id,
            title: transaction.title?.value,
            amount: transaction.amount.amount,
            intDate: Int(transaction.date.rawValue),
            categoryId: transaction.category.id,
            location: transaction.location?.value,
            tags: transaction.tags.map { $0.value }
        )
    }
    
    func toTransaction(categoryDict: [String:Transaction.Category]) -> Transaction? {
        guard let id = id else { return nil }
        guard let title = Transaction.Title(title) else { return nil }
        guard let amount = Money(amount) else { return nil }
        guard let intDate = intDate else { return nil }
        guard let date = SimpleDate(rawValue: UInt32(intDate)) else { return nil }
        guard let category = categoryDict[categoryId ?? ""] else { return nil }
        guard let location = Transaction.Location(location) else { return nil }
        let tags = Set((tags ?? []).compactMap { Transaction.Tag($0) })

        return .init(
            id: id,
            title: title,
            amount: amount,
            date: date,
            category: category,
            location: location,
            tags: tags
        )
    }
}
