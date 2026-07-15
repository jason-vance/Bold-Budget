//
//  FirebaseRecurringExpenseDoc.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/15/26.
//

import Foundation
import FirebaseFirestore

struct FirebaseRecurringExpenseDoc: Codable {

    @DocumentID var id: String?
    var name: String?
    var kind: String?
    var price: Double?
    var monthsPerCycle: Int?
    var remainingBalance: Double?
    var categoryId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case kind
        case price
        case monthsPerCycle
        case remainingBalance
        case categoryId
    }

    static func from(_ recurringExpense: RecurringExpense) -> FirebaseRecurringExpenseDoc {
        FirebaseRecurringExpenseDoc(
            id: recurringExpense.id.uuidString,
            name: recurringExpense.name.value,
            kind: recurringExpense.kind.rawValue,
            price: recurringExpense.price.amount,
            monthsPerCycle: recurringExpense.monthsPerCycle,
            remainingBalance: recurringExpense.remainingBalance?.amount,
            categoryId: recurringExpense.categoryId?.uuidString
        )
    }

    func toRecurringExpense() -> RecurringExpense? {
        guard let id = RecurringExpense.Id(uuidString: id ?? "") else { return nil }
        guard let name = RecurringExpense.Name(name) else { return nil }
        guard let kind = RecurringExpense.Kind(rawValue: kind ?? "") else { return nil }
        guard let price = Money(price) else { return nil }

        return .init(
            id: id,
            name: name,
            kind: kind,
            price: price,
            monthsPerCycle: monthsPerCycle ?? 1,
            remainingBalance: Money(remainingBalance),
            categoryId: Transaction.Category.Id(uuidString: categoryId ?? "")
        )
    }
}
