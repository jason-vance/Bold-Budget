//
//  FirebaseAccountDoc.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/21/26.
//

import Foundation
import FirebaseFirestore

struct FirebaseAccountDoc: Codable {

    struct SnapshotDoc: Codable {
        var date: Int?
        var value: Double?
    }

    @DocumentID var id: String?
    var name: String?
    var kind: String?
    var trackingMode: String?
    var balance: Double?
    var snapshots: [SnapshotDoc]?
    var monthlyPayment: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case kind
        case trackingMode
        case balance
        case snapshots
        case monthlyPayment
    }

    static func from(_ account: Account) -> FirebaseAccountDoc {
        FirebaseAccountDoc(
            id: account.id.uuidString,
            name: account.name.value,
            kind: account.kind.rawValue,
            trackingMode: account.trackingMode.rawValue,
            balance: account.balance.amount,
            snapshots: account.snapshots.map {
                SnapshotDoc(date: Int($0.date.rawValue), value: $0.value.amount)
            },
            monthlyPayment: account.monthlyPayment?.amount
        )
    }

    func toAccount() -> Account? {
        guard let id = Account.Id(uuidString: id ?? "") else { return nil }
        guard let name = Account.Name(name) else { return nil }
        guard let kind = Account.Kind(rawValue: kind ?? "") else { return nil }
        guard let trackingMode = Account.TrackingMode(rawValue: trackingMode ?? "") else { return nil }
        guard let balance = Money(balance) else { return nil }

        let snapshots: [BalanceSnapshot] = (snapshots ?? []).compactMap { doc in
            guard let rawDate = doc.date,
                  let date = SimpleDate(rawValue: SimpleDate.RawValue(rawDate)),
                  let value = Money(doc.value) else { return nil }
            return BalanceSnapshot(date: date, value: value)
        }

        return .init(
            id: id,
            name: name,
            kind: kind,
            trackingMode: trackingMode,
            balance: balance,
            snapshots: snapshots,
            monthlyPayment: Money(monthlyPayment)
        )
    }
}
