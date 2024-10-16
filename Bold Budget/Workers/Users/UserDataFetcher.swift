//
//  UserDataFetcher.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import Foundation

protocol UserDataFetcher {
    func fetchUserData(withId: UserId) async throws -> UserData
}

class MockUserDataFetcher: UserDataFetcher {
    
    var userData: UserData = .sample
    var willThrow: Bool = false
    
    func fetchUserData(withId: UserId) async throws -> UserData {
        try? await Task.sleep(for: .seconds(0.5))
        if willThrow { throw TextError("MockCurrentUserDataProvider.willThrow") }
        return userData
    }
}

extension MockUserDataFetcher {
    
    private static let envKey_TestWillThrow: String = "MockUserDataFetcher.envKey_TestWillThrow"
    
    public static func test(willThrow: Bool, in environment: inout [String:String]) {
        environment[envKey_TestWillThrow] = String(describing: willThrow)
    }
    
    static func getTestInstance() -> MockUserDataFetcher? {
        guard let willThrowString = ProcessInfo.processInfo.environment[envKey_TestWillThrow] else { return nil }
        guard let willThrow = Bool(willThrowString) else { return nil }
        
        let mock = MockUserDataFetcher()
        mock.willThrow = willThrow
        return mock
    }
}

