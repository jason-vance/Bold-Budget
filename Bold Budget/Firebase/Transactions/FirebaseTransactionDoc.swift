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
            id: transaction.id.uuidString,
            title: transaction.title?.value,
            amount: transaction.amount.amount,
            intDate: Int(transaction.date.rawValue),
            categoryId: transaction.category.id.uuidString,
            location: transaction.location?.value,
            tags: transaction.tags.map { $0.value }
        )
    }
    
    func toTransaction(categoryDict: [Transaction.Category.Id:Transaction.Category]) -> Transaction? {
        guard let id = Transaction.Id(uuidString: id ?? "") else { return nil }
        let title = Transaction.Title(title)
        guard let amount = Money(amount) else { return nil }
        guard let intDate = intDate else { return nil }
        guard let date = SimpleDate(rawValue: UInt32(intDate)) else { return nil }
        guard let categoryId = Transaction.Category.Id(uuidString: categoryId ?? "") else { return nil }
        guard let category = categoryDict[categoryId] else { return nil }
        let location = Transaction.Location(location)
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
