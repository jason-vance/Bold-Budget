//
//  UserAccountDeleter.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/12/24.
//

import Foundation
import AuthenticationServices

protocol UserAccountDeleter {
    func deleteUser(authorization: ASAuthorization) async throws
}

class MockUserAccountDeleter: UserAccountDeleter {
    func deleteUser(authorization: ASAuthorization) async throws { }
}
