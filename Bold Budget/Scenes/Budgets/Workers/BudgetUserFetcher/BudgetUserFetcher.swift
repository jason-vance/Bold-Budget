//
//  BudgetUserFetcher.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/3/25.
//

import Foundation

protocol BudgetUserFetcher {
    func fetchUsers(in budget: BudgetInfo) async throws -> [Budget.User]
}

class MockBudgetUserFetcher: BudgetUserFetcher {
    
    var users: [Budget.User] = [.sample]
    
    init(users: [Budget.User] = [.sample]) {
        self.users = users
    }
    
    func fetchUsers(in budget: BudgetInfo) async throws -> [Budget.User] {
        return users
    }
}

extension MockBudgetUserFetcher {

    private static let envKey_TestUsingSample: String = "MockBudgetUserFetcher.envKey_TestUsingSample"
    
    public static func test(usingSample: Bool, in environment: inout [String:String]) {
        environment[envKey_TestUsingSample] = String(usingSample)
    }
    
    static func getTestInstance() -> MockBudgetUserFetcher? {
        guard let useSampleStr = ProcessInfo.processInfo.environment[envKey_TestUsingSample] else { return nil }
        guard let useSample = Bool(useSampleStr) else { return nil }
        return .init(users: useSample ? [.sample] : [])
    }
}
