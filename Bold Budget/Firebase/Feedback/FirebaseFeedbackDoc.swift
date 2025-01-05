//
//  FirebaseFeedbackDoc.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/19/24.
//

import Foundation
import FirebaseFirestore

struct FirebaseFeedbackDoc: Codable {
    
    @DocumentID var id: String?
    var status: String?
    var date: Date?
    var userId: String?
    var content: String?
    var appVersion: String?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case date
        case userId
        case content
        case appVersion
    }
    
    static func from(_ feedback: UserFeedback) -> FirebaseFeedbackDoc {
        FirebaseFeedbackDoc(
            id: feedback.id.uuidString,
            status: feedback.status.rawValue,
            date: feedback.date,
            userId: feedback.userId.value,
            content: feedback.content.value,
            appVersion: feedback.appVersion
        )
    }
    
    func toUserFeedback() -> UserFeedback? {
        guard let id = UUID(uuidString: id ?? "") else { return nil }
        let status = UserFeedback.Status(rawValue: status ?? "") ?? UserFeedback.Status.unresolved
        guard let date else { return nil }
        guard let userId = UserId(userId) else { return nil }
        guard let content = UserFeedback.Content(content) else { return nil }
        guard let appVersion else { return nil }
        
        return UserFeedback(
            id: id,
            status: status,
            date: date,
            userId: userId,
            content: content,
            appVersion: appVersion
        )
    }
}
