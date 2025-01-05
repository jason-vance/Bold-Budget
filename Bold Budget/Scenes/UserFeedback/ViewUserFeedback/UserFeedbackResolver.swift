//
//  UserFeedbackResolver.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/5/25.
//

import Foundation

protocol UserFeedbackResolver {
    func updateStatus(of feedback: UserFeedback) async throws
}

class MockUserFeedbackResolver: UserFeedbackResolver {
    var error: Error?
    func updateStatus(of feedback: UserFeedback) async throws {
        if let error { throw error }
    }
}

extension MockUserFeedbackResolver {
    private static let envKey_TestWillThrow: String = "MockUserFeedbackResolver.envKey_TestWillThrow"
    
    public static func test(willThrow: Bool, in environment: inout [String:String]) {
        environment[envKey_TestWillThrow] = String(describing: willThrow)
    }
    
    static func getTestInstance() -> MockUserFeedbackResolver? {
        guard let willThrowString = ProcessInfo.processInfo.environment[envKey_TestWillThrow] else { return nil }
        guard let willThrow = Bool(willThrowString) else { return nil }
        
        let mock = MockUserFeedbackResolver()
        if willThrow {
            mock.error = TextError("MockUserFeedbackResolver.TestError")
        }
        return mock
    }
}
