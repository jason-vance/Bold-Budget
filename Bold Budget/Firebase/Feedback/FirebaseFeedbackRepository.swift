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
    func send(feedback: UserFeedback) async throws {
        let doc = FirebaseFeedbackDoc.from(feedback)
        try await feedbackCollection
            .document(feedback.id.uuidString)
            .setData(from: doc)
    }
}

extension FirebaseFeedbackRepository: UserFeedbackFetcher {
    func fetchUnresolvedUserFeedback() async throws -> [UserFeedback] {
        try await feedbackCollection
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: FirebaseFeedbackDoc.self).toUserFeedback() }
    }
}

