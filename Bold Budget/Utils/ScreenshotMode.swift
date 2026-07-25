//
//  ScreenshotMode.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/24/26.
//

import Foundation

/// Puts the app into a curated, fully mocked state that is safe and pretty to photograph.
///
/// Turned on by a single launch environment variable so the "Bold Budget (Screenshots)" scheme only
/// has to set one thing. The fixture set is built with each mock's own `test(...)` API, so renaming a
/// mock's env key can't silently drop a dependency back onto Firebase.
///
/// Every worker is mocked, including the savers and deleters: tapping Save in screenshot mode is a
/// no-op rather than a write to a real Firestore. That also means edits made while capturing don't
/// show up in the lists, since the mock fetchers hand back a fixed fixture every time.
enum ScreenshotMode {

    static let envKey: String = "BoldBudget.ScreenshotMode"

    static var isActive: Bool {
        ProcessInfo.processInfo.environment[envKey] == "1"
    }

    /// Exports the screenshot fixture set into the process environment.
    ///
    /// Must run before `setup(iocContainer:)`, which is where the mocks read their env keys.
    static func applyIfActive() {
        guard isActive else { return }

        for (key, value) in fixtureEnvironment() {
            setenv(key, value, 1)
        }
    }

    private static func fixtureEnvironment() -> [String:String] {
        var env: [String:String] = [:]

        // Signed in and onboarded as the sample user
        MockAuthenticationProvider.test(using: .signedIn, in: &env)
        MockCurrentUserIdProvider.test(using: .sample, in: &env)
        MockCurrentUserDataProvider.test(usingSample: true, in: &env)
        MockUserDataProvider.test(usingSampleUserData: true, in: &env)
        MockUserDataFetcher.test(willThrow: false, in: &env)
        MockUserDataSaver.test(willThrow: false, in: &env)
        MockUsernameAvailabilityChecker.test(returning: true, in: &env)
        MockUserFinder.test(findsUser: true, in: &env)
        MockProfileImageUploader.test(willThrow: false, in: &env)

        // Bold Budget Plus, so the Plus-gated ad slots stay out of the shot
        MockSubscriptionLevelProvider.test(subscriptionLevel: .boldBudgetPlus, in: &env)
        MockIsAdminChecker.test(isAdmin: false, in: &env)

        // The "Family Budget" fixture, with no pending invitations cluttering the list
        MockBudgetFetcher.test(usingSample: true, in: &env)
        MockBudgetUserFetcher.test(usingSample: true, in: &env)
        MockBudgetInvitationFetcher.test(usingSample: false, in: &env)
        MockBudgetSaver.test(throwing: false, in: &env)
        MockBudgetRenamer.test(throwing: false, in: &env)
        MockBudgetDeleter.test(throwing: false, in: &env)
        MockBudgetInviter.test(throwing: false, in: &env)
        MockBudgetInvitationResponder.test(throwing: false, in: &env)
        MockBudgetUserRemover.test(throwing: false, in: &env)
        MockBudgetUserRoleUpdater.test(throwing: false, in: &env)

        // Hand-picked transactions and the full category set
        MockTransactionFetcher.test(using: .screenshotSamples, in: &env)
        MockTransactionSaver.test(willThrow: false, in: &env)
        MockTransactionDeleter.test(willThrow: false, in: &env)
        MockTransactionCategoryRepo.test(using: .categorySamples, in: &env)
        MockTransactionCategorySaver.test(willThrow: false, in: &env)
        MockTransactionCategoryDeleter.test(throwing: false, in: &env)

        // Accounts and recurring expenses
        MockAccountFetcher.test(using: .samples, in: &env)
        MockAccountSaver.test(willThrow: false, in: &env)
        MockAccountDeleter.test(willThrow: false, in: &env)
        MockRecurringExpenseFetcher.test(using: .screenshotSamples, in: &env)
        MockRecurringExpenseSaver.test(willThrow: false, in: &env)
        MockRecurringExpenseDeleter.test(willThrow: false, in: &env)

        // Feedback, so the admin/support screens never touch production
        MockFeedbackSender.test(willThrow: false, in: &env)
        MockUserFeedbackFetcher.test(usingSample: true, in: &env)
        MockUserFeedbackResolver.test(willThrow: false, in: &env)

        return env
    }
}
