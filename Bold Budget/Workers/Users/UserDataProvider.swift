//
//  UserDataProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import Foundation
import Combine

protocol UserDataProvider {
    var userDataPublisher: AnyPublisher<UserData,Never> { get }
    func startListeningToUser(withId id: UserId)
    func stopListeningToUser()
}

class MockUserDataProvider: UserDataProvider {
    
    @Published var userData: UserData = .sample
    var userDataPublisher: AnyPublisher<UserData,Never> { $userData.eraseToAnyPublisher() }
    
    func startListeningToUser(withId id: UserId) {
        userData = userData
    }
    
    func stopListeningToUser() { }
}

extension MockUserDataProvider {
    
    private static let envKey_TestUsingSample: String = "MockUserDataProvider.envKey_TestUsingSample"
    
    public static func test(usingSampleUserData: Bool, in environment: inout [String:String]) {
        environment[envKey_TestUsingSample] = String(describing: usingSampleUserData)
    }
    
    static func getTestInstance() -> MockUserDataProvider? {
        guard let usingSampleString = ProcessInfo.processInfo.environment[envKey_TestUsingSample] else { return nil }
        guard let _ = Bool(usingSampleString) else { return nil }
        
        let mock = MockUserDataProvider()
        mock.userData = .sample
        return mock
    }
}
