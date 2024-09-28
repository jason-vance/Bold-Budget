//
//  StringProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation

class StringProvider {
    
    private static let envKey_string: String = "StringProvider.envKey_string"
    
    public static func setValueOf(string: String, in launchEnvironment: inout [String:String]) {
        launchEnvironment[StringProvider.envKey_string] = string
    }
    
    static func getInstance() -> StringProvider { .init() }
    
    var string: String
    
    init() {
        self.string = ProcessInfo.processInfo.environment[Self.envKey_string] ?? "The default message value"
    }
}
