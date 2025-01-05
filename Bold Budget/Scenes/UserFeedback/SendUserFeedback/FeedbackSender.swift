//
//  FeedbackSender.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/19/24.
//

import Foundation

protocol FeedbackSender {
    func send(feedback: UserFeedback) async throws
}

class MockFeedbackSender: FeedbackSender {
    var willThrow: Bool = false
    func send(feedback: UserFeedback) async throws {
        if willThrow {
            throw TextError("MockFeedbackSender.WiilThrowError")
        }
    }
}

extension MockFeedbackSender {
    private static let envKey_TestWillThrow: String = "MockFeedbackSender.envKey_TestWillThrow"
    
    public static func test(willThrow: Bool, in environment: inout [String:String]) {
        environment[envKey_TestWillThrow] = String(describing: willThrow)
    }
    
    static func getTestInstance() -> MockFeedbackSender? {
        guard let willThrowString = ProcessInfo.processInfo.environment[envKey_TestWillThrow] else { return nil }
        guard let willThrow = Bool(willThrowString) else { return nil }
        
        let mock = MockFeedbackSender()
        mock.willThrow = willThrow
        return mock
    }
}
