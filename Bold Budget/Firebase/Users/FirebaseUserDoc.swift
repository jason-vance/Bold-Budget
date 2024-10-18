//
//  FirebaseUserDoc.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import Foundation
import FirebaseFirestore

struct FirebaseUserDoc: Codable {
    
    @DocumentID var id: String?
    var username: String?
    var profileImageUrl: URL?
    var termsOfServiceAcceptance: Date?
    var privacyPolicyAcceptance: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case profileImageUrl
        case termsOfServiceAcceptance
        case privacyPolicyAcceptance
    }
    
    static func from(_ userData: UserData) -> FirebaseUserDoc {
        FirebaseUserDoc(
            id: userData.id.value,
            username: userData.username?.value,
            profileImageUrl: userData.profileImageUrl,
            termsOfServiceAcceptance: userData.termsOfServiceAcceptance,
            privacyPolicyAcceptance: userData.privacyPolicyAcceptance
        )
    }
    
    func toUserData() -> UserData? {
        guard let id = UserId(id) else { return nil }
        guard let username = Username(username) else { return nil }

        return .init(
            id: id,
            username: username,
            profileImageUrl: profileImageUrl,
            termsOfServiceAcceptance: termsOfServiceAcceptance,
            privacyPolicyAcceptance: privacyPolicyAcceptance
        )
    }
}
