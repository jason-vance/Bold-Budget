//
//  UserSignOutService.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/12/24.
//

import Foundation

protocol UserSignOutService {
    func signOut() throws
}

class MockUserSignOutService: UserSignOutService {
    func signOut() throws { }
}
