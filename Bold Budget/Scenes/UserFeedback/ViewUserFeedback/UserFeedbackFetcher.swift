//
//  UserFeedbackFetcher.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/5/25.
//

import Foundation

protocol UserFeedbackFetcher {
    func fetchUnresolvedUserFeedback() async throws -> [UserFeedback]
}

class MockUserFeedbackFetcher: UserFeedbackFetcher {
    
    var feedback: [UserFeedback] = []
    
    init(feedback: [UserFeedback]) {
        self.feedback = feedback
    }
    
    func fetchUnresolvedUserFeedback() async throws -> [UserFeedback] {
        return []
    }
}

extension MockUserFeedbackFetcher {

    private static let envKey_TestUsingSample: String = "MockUserFeedbackFetcher.envKey_TestUsingSample"
    
    public static func test(usingSample: Bool, in environment: inout [String:String]) {
        environment[envKey_TestUsingSample] = String(usingSample)
    }
    
    static func getTestInstance() -> MockUserFeedbackFetcher? {
        guard let usingSampleString = ProcessInfo.processInfo.environment[envKey_TestUsingSample] else { return nil }
        guard let usingSample = Bool(usingSampleString) else { return nil }
        return .init(feedback: usingSample ? [.sample] : [])
    }
}
