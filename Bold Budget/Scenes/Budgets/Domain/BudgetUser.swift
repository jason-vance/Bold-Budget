//
//  BudgetUser.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/3/25.
//

import Foundation

extension Budget {
    struct User {
        
        enum Role: String {
            case owner
        }
        
        let id: UserId
        let role: Role
        
        static let sample: User = .init(id: .sample, role: .owner)
    }
}

extension Budget.User: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.role == rhs.role
    }
}
