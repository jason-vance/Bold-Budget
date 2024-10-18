//
//  FirebaseUserRepository.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseUserRepository {
    
    static let USERS = "Users"
    
    let usersCollection = Firestore.firestore().collection(USERS)
    
    let usernameField = FirebaseUserDoc.CodingKeys.username.rawValue
    
    func createOrUpdateUserDocument(with userData: UserData) async throws {
        if try await usersCollection.document(userData.id.value).getDocument().exists {
            try await updateUserDocument(with: userData)
        } else {
            try await createUserDocument(with: userData)
        }
    }
    
    private func createUserDocument(with userData: UserData) async throws {
        let userDoc = FirebaseUserDoc.from(userData)
        try await usersCollection.document(userData.id.value).setData(from: userDoc)
    }
    
    private func updateUserDocument(with userData: UserData) async throws {
        var dict: [AnyHashable : Any] = [:]
        dict[FirebaseUserDoc.CodingKeys.username.rawValue] = userData.username?.value
        dict[FirebaseUserDoc.CodingKeys.profileImageUrl.rawValue] = userData.profileImageUrl?.absoluteString
        if let termsOfServiceAcceptance = userData.termsOfServiceAcceptance {
            dict[FirebaseUserDoc.CodingKeys.termsOfServiceAcceptance.rawValue] = termsOfServiceAcceptance
        }
        if let privacyPolicyAcceptance = userData.privacyPolicyAcceptance {
            dict[FirebaseUserDoc.CodingKeys.privacyPolicyAcceptance.rawValue] = privacyPolicyAcceptance
        }

        try await usersCollection.document(userData.id.value).updateData(dict)
    }
    
    func listenToUserDocument(
        withId id: UserId,
        onUpdate: @escaping (FirebaseUserDoc?)->(),
        onError: ((Error)->())? = nil
    ) -> ListenerRegistration {
        usersCollection.document(id.value).addSnapshotListener { snapshot, error in
            if let snapshot = snapshot {
                let userDoc = try? snapshot.data(as: FirebaseUserDoc.self)
                onUpdate(userDoc)
            } else if let error = error {
                onError?(error)
            } else {
                onError?(TextError("¯\\_(ツ)_/¯ While listening to user doc changes"))
            }
        }
    }
    
    func fetchUserDocument(withId id: String) async throws -> FirebaseUserDoc? {
        let snapshot = try await usersCollection.document(id).getDocument()
        return try? snapshot.data(as: FirebaseUserDoc.self)
    }
    
    func deleteUserDoc(withId userId: String) async throws {
        try await usersCollection.document(userId).delete()
    }
}

extension FirebaseUserRepository: UserDataSaver {
    func saveOnboarding(userData: UserData) async throws {
        try await createOrUpdateUserDocument(with: userData)
    }
}

extension FirebaseUserRepository: UsernameAvailabilityChecker {
    func isAvailable(username: Username, forUser userId: UserId) async throws -> Bool {
        try await usersCollection
            .whereField(usernameField, isEqualTo: username.value)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: FirebaseUserDoc.self) }
            .filter { $0.id != userId.value }
            .count == 0
    }
}

extension FirebaseUserRepository: UserDataFetcher {
    func fetchUserData(withId userId: UserId) async throws -> UserData {
        let document = try await usersCollection
            .document(userId.value)
            .getDocument()
        
        guard document.exists else { throw TextError("") }
        
        guard let userData = try document
            .data(as: FirebaseUserDoc.self)
            .toUserData()
        else {
            throw TextError("Unable to fetch UserData with id '\(userId.value)'")
        }
        
        return userData
    }
}
