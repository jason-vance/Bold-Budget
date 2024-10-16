//
//  UsernameAvailabilityChecker.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import Foundation

protocol UsernameAvailabilityChecker {
    func isAvailable(username: Username, forUser userId: UserId) async throws -> Bool
}

class MockUsernameAvailabilityChecker: UsernameAvailabilityChecker {
    
    var isAvailable: Bool = true
    
    func isAvailable(username: Username, forUser userId: UserId) async throws -> Bool {
        try await Task.sleep(for: .seconds(1))
        return isAvailable
    }
}

extension MockUsernameAvailabilityChecker {
    
    private static let envKey_TestReturning: String = "MockUsernameAvailabilityChecker.envKey_TestUsingSample"
    
    public static func test(returning isAvailable: Bool, in environment: inout [String:String]) {
        environment[envKey_TestReturning] = String(describing: isAvailable)
    }
    
    static func getTestInstance() -> MockUsernameAvailabilityChecker? {
        guard let isAvailableString = ProcessInfo.processInfo.environment[envKey_TestReturning] else { return nil }
        guard let isAvailable = Bool(isAvailableString) else { return nil }
        
        let mock = MockUsernameAvailabilityChecker()
        mock.isAvailable = isAvailable
        return mock
    }
}
