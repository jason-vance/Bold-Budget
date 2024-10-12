//
//  TextError.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/11/24.
//

import Foundation

struct TextError: Error, LocalizedError {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    public var errorDescription: String? { text }
}
