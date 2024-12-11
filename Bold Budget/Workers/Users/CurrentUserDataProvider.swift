//
//  CurrentUserDataProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/17/24.
//

import Foundation
import Combine

protocol CurrentUserDataProvider {
    var currentUserDataPublisher: AnyPublisher<UserData?,Never> { get }
    func onNew(userData: UserData)
}

class MockCurrentUserDataProvider: CurrentUserDataProvider {
    
    @Published var currentUserData: UserData?
    var currentUserDataPublisher: AnyPublisher<UserData?,Never> { $currentUserData.eraseToAnyPublisher() }
    
    init(currentUserData: UserData? = .sample) {
        self.currentUserData = currentUserData
    }
    
    func onNew(userData: UserData) {
        currentUserData = userData
    }
}

extension MockCurrentUserDataProvider {

    private static let envKey_TestUsingSample: String = "MockCurrentUserDataProvider.envKey_TestUsingSample"
    
    public static func test(usingSample: Bool, in environment: inout [String:String]) {
        environment[envKey_TestUsingSample] = String(usingSample)
    }
    
    static func getTestInstance() -> MockCurrentUserDataProvider? {
        guard let useSampleStr = ProcessInfo.processInfo.environment[envKey_TestUsingSample] else { return nil }
        guard let useSample = Bool(useSampleStr) else { return nil }
        return .init(currentUserData: useSample ? UserData.sample : nil)
    }
}
