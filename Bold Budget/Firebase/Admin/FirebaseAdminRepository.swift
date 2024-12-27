//
//  FirebaseAdminRepository.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/26/24.
//

import Foundation
import FirebaseFirestore

class FirebaseAdminRepository {
    
    public static let ADMIN = "Admin"
    
    private let adminCollection = Firestore.firestore().collection(ADMIN)
}

extension FirebaseAdminRepository: IsAdminChecker {
    func isAdmin(userId: UserId) async throws -> Bool {
        try await adminCollection.document(userId.value).getDocument().exists
    }
}
