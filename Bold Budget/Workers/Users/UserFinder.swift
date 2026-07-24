//
//  UserFinder.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation

protocol UserFinder {
    /// Looks up a user by their exact username. Returns `nil` when no such user exists.
    func findUser(byUsername username: Username) async throws -> UserData?
}

class MockUserFinder: UserFinder {

    var user: UserData?

    init(user: UserData? = .sample) {
        self.user = user
    }

    func findUser(byUsername username: Username) async throws -> UserData? {
        try await Task.sleep(for: .seconds(0.5))
        return user
    }
}

extension MockUserFinder {

    private static let envKey_TestFindsUser: String = "MockUserFinder.envKey_TestFindsUser"

    public static func test(findsUser: Bool, in environment: inout [String:String]) {
        environment[envKey_TestFindsUser] = String(findsUser)
    }

    static func getTestInstance() -> MockUserFinder? {
        guard let findsUserStr = ProcessInfo.processInfo.environment[envKey_TestFindsUser] else { return nil }
        guard let findsUser = Bool(findsUserStr) else { return nil }
        return .init(user: findsUser ? .sample : nil)
    }
}
