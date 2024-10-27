//
//  FirebaseBudgetDoc.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/22/24.
//

import Foundation
import FirebaseFirestore

struct FirebaseBudgetDoc: Codable {
    
    @DocumentID var id: String?
    var name: String?
    var users: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case users
    }
    
    static func from(_ budget: Budget) -> FirebaseBudgetDoc {
        FirebaseBudgetDoc(
            id: budget.id,
            name: budget.name.value,
            users: budget.users.map { $0.value }
        )
    }
    
    func toBudget() -> Budget? {
        guard let id = id else { return nil }
        guard let name = Budget.Name(name) else { return nil }
        guard let users = users else { return nil }

        return .init(
            id: id,
            name: name,
            users: users.compactMap { UserId($0) }
        )
    }
}
