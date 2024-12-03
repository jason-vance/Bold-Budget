//
//  BudgetInfo.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/20/24.
//

import Foundation

struct BudgetInfo {
    let id: String
    let name: Name
    let users: [UserId]
    
    static let sample: BudgetInfo = .init(
        id: UUID().uuidString,
        name: .sample,
        users: [.sample]
    )
}

extension BudgetInfo: Identifiable {}
extension BudgetInfo: Equatable {}

extension BudgetInfo {
    struct Name: Equatable {
        
        private static let minTextLength = 3
        private static let maxTextLength = 32

        let value: String
        
        init?(_ value: String?) {
            guard let value = value else { return nil }
            
            // Trim whitespace
            let trimmedText = value.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for minimum and maximum length
            guard trimmedText.count >= Self.minTextLength else { return nil }
            guard trimmedText.count <= Self.maxTextLength else { return nil }

            self.value = trimmedText
        }
        
        static var sample: Name {
            .init("Test Budget")!
        }
    }
}
