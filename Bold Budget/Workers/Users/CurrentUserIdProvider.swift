//
//  CurrentUserIdProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/11/24.
//

import Foundation
import Combine

protocol CurrentUserIdProvider {
    var currentUserId: UserId? { get }
    var currentUserIdPublisher: AnyPublisher<UserId?,Never> { get }
}

class MockCurrentUserIdProvider: CurrentUserIdProvider {
    
    @Published var currentUserId: UserId?
    var currentUserIdPublisher: AnyPublisher<UserId?,Never> { $currentUserId.eraseToAnyPublisher() }
    
    init(currentUserId: UserId? = .sample) {
        self.currentUserId = currentUserId
    }
}

extension MockCurrentUserIdProvider {

    private static let envKey_TestUserId: String = "MockCurrentUserIdProvider.envKey_TestUserId"
    
    public static func test(using userId: UserId, in environment: inout [String:String]) {
        environment[MockCurrentUserIdProvider.envKey_TestUserId] = userId.value
    }
    
    static func getTestInstance() -> MockCurrentUserIdProvider? {
        if let testUserId = UserId(ProcessInfo.processInfo.environment[Self.envKey_TestUserId]) {
            return .init(currentUserId: testUserId)
        }
        return nil
    }
}
