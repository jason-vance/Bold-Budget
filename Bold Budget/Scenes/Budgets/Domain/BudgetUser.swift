//
//  BudgetUser.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/3/25.
//

import Foundation

extension Budget {
    struct User {
        
        enum Role: String, CaseIterable {
            case owner
            case viewer

            /// Owners have full read/write powers; viewers may only view. Mirrors the
            /// Firestore rules, which gate writes on `role == 'owner'`.
            var canEdit: Bool { self == .owner }

            /// Human-readable label for pickers and role badges.
            var displayName: String {
                switch self {
                case .owner: return String(localized: "Owner")
                case .viewer: return String(localized: "Viewer")
                }
            }
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
