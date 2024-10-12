//
//  UserId.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/11/24.
//

import Foundation

struct UserId {
    
    static let minTextLength: Int = 3

    let value: String
    
    init?(_ value: String?) {
        guard let value = value else { return nil }
        
        // Trim whitespace
        let trimmedText = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for minimum and maximum length
        guard trimmedText.count >= Self.minTextLength else { return nil }
        
        self.value = trimmedText
    }
    
    static let sample: UserId = .init(UUID().uuidString)!
}

extension UserId: Equatable { }
