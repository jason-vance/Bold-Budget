//
//  PopupNotification.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/11/25.
//

import Foundation

struct PopupNotification: Identifiable, Equatable {
    let id = UUID().uuidString
    let title: String
    let subtitle: String?
    let sfSymbol: String?
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
