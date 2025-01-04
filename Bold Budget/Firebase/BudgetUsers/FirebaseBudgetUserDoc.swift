//
//  FirebaseBudgetUserDoc.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/26/24.
//

import Foundation
import FirebaseFirestore

struct FirebaseBudgetUserDoc: Codable {
    
    var userId: String?
    var role: String?

    enum CodingKeys: String, CodingKey {
        case userId
        case role
    }
    
    static func from(user: Budget.User) -> FirebaseBudgetUserDoc {
        .init(
            userId: user.id.value,
            role: user.role.rawValue
        )
    }
    
    func toBudgetUser() -> Budget.User? {
        guard let userId = UserId(userId) else { return nil }
        guard let role = Budget.User.Role(rawValue: role ?? "") else { return nil }
        
        return Budget.User(
            id: userId,
            role: role
        )
    }
}
