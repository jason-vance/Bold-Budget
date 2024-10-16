//
//  DocumentReferenceExtensions.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import Foundation
import FirebaseFirestore

extension DocumentReference {
    
    func setData<T>(from value: T) async throws where T : Encodable {
        try await withCheckedThrowingContinuation { (continuation:CheckedContinuation<Void,Error>) in
            do {
                try self.setData(from: value) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
