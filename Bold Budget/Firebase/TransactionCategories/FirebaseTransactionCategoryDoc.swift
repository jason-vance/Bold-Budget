//
//  FirebaseTransactionCategoryDoc.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/25/24.
//

import Foundation
import FirebaseFirestore

struct FirebaseTransactionCategoryDoc: Codable {
    
    @DocumentID var id: String?
    var kind: String?
    var name: String?
    var sfSymbol: String?

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case name
        case sfSymbol
    }
    
    static func from(_ category: Transaction.Category) -> FirebaseTransactionCategoryDoc {
        FirebaseTransactionCategoryDoc(
            id: category.id,
            kind: category.kind.rawValue,
            name: category.name.value,
            sfSymbol: category.sfSymbol.value
        )
    }
    
    func toCategory() -> Transaction.Category? {
        guard let id = id else { return nil }
        guard let kind = Transaction.Category.Kind(rawValue: kind ?? "") else { return nil }
        guard let name = Transaction.Category.Name(name) else { return nil }
        guard let sfSymbol = Transaction.Category.SfSymbol(sfSymbol) else { return nil }

        return .init(
            id: id,
            kind: kind,
            name: name,
            sfSymbol: sfSymbol
        )
    }
}
