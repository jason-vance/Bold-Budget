//
//  Feedback.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/19/24.
//

import Foundation

struct Feedback {
    let date: Date
    let userId: UserId
    let content: Content
    let appVersion: String
}

extension Feedback {
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
        
        static let sample: Feedback.Content = .init("Lorem ipsum dolor sit amet, consectetur adipiscing")!
    }
}
