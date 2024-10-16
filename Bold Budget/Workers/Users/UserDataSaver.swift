//
//  UserDataSaver.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import Foundation

protocol UserDataSaver {
    func saveOnboarding(userData: UserData) async throws
}

class MockUserDataSaver: UserDataSaver {
    
    var willThrow = false
    
    func saveOnboarding(userData: UserData) async throws {
        try? await Task.sleep(for: .seconds(1))
        if willThrow { throw TextError("MockUserDataSaver.willThrow = \(willThrow)") }
    }
}

extension MockUserDataSaver {
    
    private static let envKey_TestWillThrow: String = "MockUserDataSaver.envKey_TestWillThrow"
    
    public static func test(willThrow: Bool, in environment: inout [String:String]) {
        environment[envKey_TestWillThrow] = String(describing: willThrow)
    }
    
    static func getTestInstance() -> MockUserDataSaver? {
        guard let willThrowString = ProcessInfo.processInfo.environment[envKey_TestWillThrow] else { return nil }
        guard let willThrow = Bool(willThrowString) else { return nil }
        
        let mock = MockUserDataSaver()
        mock.willThrow = willThrow
        return mock
    }
}

