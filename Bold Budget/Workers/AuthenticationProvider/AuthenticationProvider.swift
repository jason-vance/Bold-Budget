//
//  AuthenticationProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/11/24.
//

import Foundation
import AuthenticationServices

 protocol AuthenticationProvider {
     var userAuthStatePublisher: Published<UserAuthState>.Publisher { get }
     func signIn(withResult result: Result<ASAuthorization, Error>) async throws
 }

class MockAuthenticationProvider: AuthenticationProvider {
    
    @Published private var userAuthState: UserAuthState = .loggedOut
    var userAuthStatePublisher: Published<UserAuthState>.Publisher { $userAuthState }
    
    init(userAuthState: UserAuthState) {
        self.userAuthState = userAuthState
    }
    
    func signIn(withResult result: Result<ASAuthorization, any Error>) async throws { }
}

extension MockAuthenticationProvider {
    public enum TestState: String, RawRepresentable {
        case signedOut
        case signedIn
    }
    
    private static let envKey_TestState: String = "MockAuthenticationProvider.envKey_TestState"
    
    public static func test(using testState: TestState = .signedIn, in environment: inout [String:String]) {
        environment[MockAuthenticationProvider.envKey_TestState] = testState.rawValue
    }
    
    private static func getTestAuthState() -> UserAuthState? {
        if let testState = TestState(rawValue: ProcessInfo.processInfo.environment[Self.envKey_TestState] ?? "") {
            switch testState {
            case .signedIn: return .loggedIn
            case .signedOut: return .loggedOut
            }
        }
        return nil
    }
    
    static func getTestInstance() -> MockAuthenticationProvider? {
        if var testState = Self.getTestAuthState() {
            return .init(
                userAuthState: testState
            )
        }
        return nil
    }
}
