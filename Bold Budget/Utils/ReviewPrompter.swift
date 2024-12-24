//
//  ReviewPrompter.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/23/24.
//

import Foundation
import _StoreKit_SwiftUI

class ReviewPrompter {
    
    private let secondsPerDay: TimeInterval = 60 * 60 * 24
    private let reviewPrompInterval: TimeInterval = 60 * 60 * 24 * 5 // 5 days
    
    private let firstAppLaunchKey: String = "ReviewPrompterTracker.firstAppLaunch"
    private let lastReviewPromptKey: String = "ReviewPrompterTracker.lastReviewPrompt"
    
    private var firstAppLaunch: Date? {
        get {
            UserDefaults.standard.object(forKey: firstAppLaunchKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: firstAppLaunchKey)
        }
    }
    
    private var lastReviewPrompt: Date? {
        get {
            UserDefaults.standard.object(forKey: lastReviewPromptKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastReviewPromptKey)
        }
    }

    func trackAppLaunch() {
        guard firstAppLaunch == nil else { return }
        firstAppLaunch = Date()
    }
    
    @MainActor
    func promptForReviewIfAppropriate(promptForReview: RequestReviewAction) {
        let referenceDate = lastReviewPrompt ?? firstAppLaunch ?? Date()
        let numberOfDaysSinceLastReviewPrompt: Double = Date().timeIntervalSince(referenceDate) / secondsPerDay
        guard numberOfDaysSinceLastReviewPrompt > reviewPrompInterval else { return }
        lastReviewPrompt = Date()
        promptForReview()
    }
}
