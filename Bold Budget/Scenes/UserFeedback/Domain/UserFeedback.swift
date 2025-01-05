//
//  UserFeedback.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/19/24.
//

import Foundation

struct UserFeedback: Identifiable {
    let id: UUID
    let status: Status
    let date: Date
    let userId: UserId
    let content: Content
    let appVersion: String
    
    func with(status: Status) -> Self {
        Self(id: id, status: status, date: date, userId: userId, content: content, appVersion: appVersion)
    }
    
    static let sample: UserFeedback = .init(
        id: UUID(),
        status: .unresolved,
        date: Date(),
        userId: .sample,
        content: .sample,
        appVersion: "0.0.0"
    )
}

extension UserFeedback {
    enum Status: String, CaseIterable {
        case unresolved
        case resolved
    }
}

extension UserFeedback: Equatable { }

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

extension UserFeedback.Content: Equatable {
    static func == (lhs: UserFeedback.Content, rhs: UserFeedback.Content) -> Bool {
        lhs.value == rhs.value
    }
}
