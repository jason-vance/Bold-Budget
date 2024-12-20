//
//  FirebaseFeedbackRepository.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/19/24.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseFeedbackRepository {
    
    static let FEEDBACK = "Feedback"
    
    let feedbackCollection = Firestore.firestore().collection(FEEDBACK)
}

extension FirebaseFeedbackRepository: FeedbackSender {
    func send(feedback: Feedback) async throws {
        try await withCheckedThrowingContinuation { (continuation:CheckedContinuation<Void, Error>) in
            do {
                let doc = FirebaseFeedbackDoc.from(feedback)
                try feedbackCollection.addDocument(from: doc) { error in
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

