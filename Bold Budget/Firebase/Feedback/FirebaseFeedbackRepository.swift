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
            .whereField(FirebaseFeedbackDoc.CodingKeys.status.rawValue, isNotEqualTo: UserFeedback.Status.resolved.rawValue)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: FirebaseFeedbackDoc.self).toUserFeedback() }
    }
}

extension FirebaseFeedbackRepository: UserFeedbackResolver {
    func updateStatus(of feedback: UserFeedback) async throws {
        try await feedbackCollection
            .document(feedback.id.uuidString)
            .updateData([
                FirebaseFeedbackDoc.CodingKeys.status.rawValue: feedback.status.rawValue
            ])
    }
}
