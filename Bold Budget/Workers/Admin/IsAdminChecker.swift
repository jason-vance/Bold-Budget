//
//  IsAdminChecker.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/26/24.
//

import Foundation

protocol IsAdminChecker {
    func isAdmin(userId: UserId) async throws -> Bool
}

class MockIsAdminChecker: IsAdminChecker {
    
    public var isAdmin: Bool = false
    
    func isAdmin(userId: UserId) async throws -> Bool {
        try await Task.sleep(for: .seconds(1))
        return isAdmin
    }
}

extension MockIsAdminChecker {
    private static let envKey_TestIsAdmin: String = "MockIsAdminChecker.envKey_TestIsAdmin"
    
    public static func test(isAdmin: Bool, in environment: inout [String:String]) {
        environment[envKey_TestIsAdmin] = String(describing: isAdmin)
    }
    
    static func getTestInstance() -> MockIsAdminChecker? {
        guard let isAdminString = ProcessInfo.processInfo.environment[envKey_TestIsAdmin] else { return nil }
        guard let isAdmin = Bool(isAdminString) else { return nil }
        
        let mock = MockIsAdminChecker()
        mock.isAdmin = isAdmin
        return mock
    }
}
