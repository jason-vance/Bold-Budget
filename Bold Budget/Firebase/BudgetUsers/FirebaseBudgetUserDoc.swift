//
//  FirebaseBudgetUserDoc.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/26/24.
//

import Foundation
import FirebaseFirestore

struct FirebaseBudgetUserDoc: Codable {
    
    enum Role: String, Codable {
        case owner
    }
    
    var userId: String?
    var role: Role?

    enum CodingKeys: String, CodingKey {
        case userId
        case role
    }
}
