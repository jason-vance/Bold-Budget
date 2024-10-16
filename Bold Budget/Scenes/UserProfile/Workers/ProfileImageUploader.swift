//
//  ProfileImageUploader.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import Foundation
import UIKit

protocol ProfileImageUploader {
    func upload(profileImage: UIImage, for userId: UserId) async throws -> URL
}

class MockProfileImageUploader: ProfileImageUploader {
    
    var returnUrl: URL = URL(string: "https://static1.cbrimages.com/wordpress/wp-content/uploads/2023/06/final-fantasy-xvi-clive-profile.jpg")!
    var willThrow = false
    
    func upload(profileImage: UIImage, for userId: UserId) async throws -> URL {
        try? await Task.sleep(for: .seconds(0.5))
        if willThrow { throw TextError("error") }
        return returnUrl
    }
}

extension MockProfileImageUploader {
    
    private static let envKey_TestWillThrow: String = "MockProfileImageUploader.envKey_TestWillThrow"
    
    public static func test(willThrow: Bool, in environment: inout [String:String]) {
        environment[envKey_TestWillThrow] = String(describing: willThrow)
    }
    
    static func getTestInstance() -> MockProfileImageUploader? {
        guard let willThrowString = ProcessInfo.processInfo.environment[envKey_TestWillThrow] else { return nil }
        guard let willThrow = Bool(willThrowString) else { return nil }
        
        let mock = MockProfileImageUploader()
        mock.willThrow = willThrow
        return mock
    }
}


