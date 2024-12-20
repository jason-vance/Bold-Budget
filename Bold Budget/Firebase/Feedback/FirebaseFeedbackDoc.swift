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
    var date: Date?
    var userId: String?
    var content: String?
    var appVersion: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case content
        case appVersion
    }
    
    static func from(_ feedback: Feedback) -> FirebaseFeedbackDoc {
        FirebaseFeedbackDoc(
            id: nil,
            date: feedback.date,
            userId: feedback.userId.value,
            content: feedback.content.value,
            appVersion: feedback.appVersion
        )
    }
}
