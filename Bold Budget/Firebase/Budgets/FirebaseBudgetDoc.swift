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
    var owner: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case owner
    }
    
    static func from(_ budget: Budget) -> FirebaseBudgetDoc {
        FirebaseBudgetDoc(
            id: budget.id,
            name: budget.name.value,
            owner: budget.owner.value
        )
    }
    
    func toBudget() -> Budget? {
        guard let id = id else { return nil }
        guard let name = Budget.Name(name) else { return nil }
        guard let owner = UserId(owner) else { return nil }

        return .init(
            id: id,
            name: name,
            owner: owner
        )
    }
}
