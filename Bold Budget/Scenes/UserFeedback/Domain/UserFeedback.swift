//
//  UserFeedback.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/19/24.
//

import Foundation

struct UserFeedback: Identifiable {
    let id: UUID
    let date: Date
    let userId: UserId
    let content: Content
    let appVersion: String
    
    static let sample: UserFeedback = .init(
        id: UUID(),
        date: Date(),
        userId: .sample,
        content: .sample,
        appVersion: "0.0.0"
    )
}

extension UserFeedback: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension UserFeedback {
    class Content {
        
        static let minTextLength: Int = 3
        static let maxTextLength: Int = 2000

        let value: String
        
        init?(_ value: String?) {
            guard let value = value else { return nil }
            
            // Trim whitespace
            let trimmedText = value.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for minimum and maximum length
            guard trimmedText.count >= Self.minTextLength, trimmedText.count <= Self.maxTextLength else {
                return nil
            }
            
            // Convert to lowercase
            self.value = trimmedText
        }
        
        static let sample: UserFeedback.Content = .init("Lorem ipsum dolor sit amet, consectetur adipiscing")!
    }
}
