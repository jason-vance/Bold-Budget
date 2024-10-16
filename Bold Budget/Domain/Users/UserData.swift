//
//  UserData.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import Foundation

struct UserData {
    var id: UserId
    var username: Username?
    var profileImageUrl: URL?
    var termsOfServiceAcceptance: Date?
    var privacyPolicyAcceptance: Date?
    
    var isFullyOnboarded: Bool {
        username != nil &&
        termsOfServiceAcceptance != nil &&
        privacyPolicyAcceptance != nil
    }
}

extension UserData {
    
    static let sample = UserData(
        id: UserId("userId")!,
        username: Username("ifrit"),
        profileImageUrl: URL(string:"https://static1.cbrimages.com/wordpress/wp-content/uploads/2023/06/final-fantasy-xvi-clive-profile.jpg")
    )
}
