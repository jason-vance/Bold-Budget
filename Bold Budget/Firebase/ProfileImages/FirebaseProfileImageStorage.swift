//
//  FirebaseProfileImageStorage.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import Foundation
import FirebaseStorage
import UIKit

class FirebaseProfileImageStorage {
    
    var storage: Storage { Storage.storage() }
    
    private func userProfileImagePath(userId: UserId) -> String {
        "ProfileImages/\(userId)/\(userId).jpg"
    }
    
    func upload(profileImage: UIImage, for userId: UserId) async throws -> URL {
        let path = userProfileImagePath(userId: userId)
        return try await upload(image: profileImage, to: path)
    }
    
    private func upload(image: UIImage, to path: String) async throws -> URL {
        guard let jpgImage = image.jpegData(compressionQuality: 0.5) else {
            throw TextError("Image could not be converted to jpg")
        }
        return try await upload(jpgImage: jpgImage, to: path)
    }
    
    private func upload(jpgImage: Data, to path: String) async throws -> URL {
        let storageReference = storage.reference(withPath: path)
        let storageMetadata = StorageMetadata()
        storageMetadata.contentType = "image/jpeg"
        
        try await withCheckedThrowingContinuation { (continuation:CheckedContinuation<Void,Error>) in
            let uploadTask = storageReference.putData(jpgImage, metadata: storageMetadata)
            uploadTask.observe(.failure) { taskSnapshot in
                continuation.resume(throwing: taskSnapshot.error ?? TextError("Failed to upload image"))
            }
            uploadTask.observe(.success) { taskSnapshot in
                continuation.resume()
            }
        }
        return try await storageReference.downloadURL()
    }
    
    func deleteProfileImage(for userId: UserId) async throws {
        let path = userProfileImagePath(userId: userId)
        let storageReference = storage.reference(withPath: path)
        try await storageReference.delete()
    }
}

extension FirebaseProfileImageStorage: ProfileImageUploader {}
