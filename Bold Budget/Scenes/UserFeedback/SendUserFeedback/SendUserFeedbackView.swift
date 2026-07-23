//
//  SendUserFeedbackView.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/17/24.
//

import SwiftUI
import MessageUI
import SwinjectAutoregistration

struct SendUserFeedbackView: View {

    @Environment(\.dismiss) private var dismiss: DismissAction

    @State private var feedbackString: String = ""

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private let currentUserIdProvider: CurrentUserIdProvider
    private let feedbackSender: FeedbackSender

    init() {
        self.init(
            currentUserIdProvider: iocContainer~>CurrentUserIdProvider.self,
            feedbackSender: iocContainer~>FeedbackSender.self
        )
    }

    init (
        currentUserIdProvider: CurrentUserIdProvider,
        feedbackSender: FeedbackSender
    ) {
        self.currentUserIdProvider = currentUserIdProvider
        self.feedbackSender = feedbackSender
    }

    private var appVersion: String {
        "\(AppInfo.versionString)(\(AppInfo.buildNumberString))"
    }

    private var currentUserId: UserId? { currentUserIdProvider.currentUserId }

    private var isFormComplete: Bool { feedback != nil }

    private var feedback: UserFeedback? {
        guard let userId = currentUserId else { return nil }
        guard let content = UserFeedback.Content.init(feedbackString) else { return nil }

        return .init(
            id: UUID(),
            status: .unresolved,
            date: .now,
            userId: userId,
            content: content,
            appVersion: appVersion
        )
    }

    private func sendFeedback() async -> TaskStatus {
        do {
            guard let feedback = feedback else { throw TextError("Incomplete Feedback") }

            try await feedbackSender.send(feedback: feedback)
            dismiss()
            return .success
        } catch {
            let errorMsg = "Error sending feedback. \(error.localizedDescription)"
            print(errorMsg)
            return .failed(errorMsg)
        }
    }

    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }

    private var feedbackInstructions: String {
        if feedbackString.isEmpty { return "" }
        if feedbackString.count < UserFeedback.Content.minTextLength { return "Too short" }
        if feedbackString.count > UserFeedback.Content.maxTextLength { return "Too long" }
        return "\(feedbackString.count)/\(UserFeedback.Content.maxTextLength)"
    }

    var body: some View {
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(spacing: .padding) {
                    FeedbackContentField()
                    SendButton()
                        .padding(.top, .paddingSmall)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .alert(alertMessage, isPresented: $showAlert) {}
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text("Submit Feedback")
                .font(.headline)
                .foregroundStyle(Color.appText)
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                }
                .accessibilityIdentifier("SendUserFeedbackView.DismissButton")
                Spacer(minLength: 0)
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Feedback

    @ViewBuilder func FeedbackContentField() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Your Feedback")
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .kerning(0.5)
                    .foregroundStyle(Color.appMutedText)
                Spacer(minLength: 0)
                Text(feedbackInstructions)
                    .font(.caption2)
                    .foregroundStyle(Color.appMutedText)
                    .animation(.snappy, value: feedbackInstructions)
            }
            TextField(
                "Feedback",
                text: $feedbackString,
                prompt: Text("What do you think about Bold Budget?").foregroundStyle(Color.appMutedText),
                axis: .vertical
            )
            .font(.title3)
            .foregroundStyle(Color.appText)
            .tint(Color.brandTeal)
            .lineLimit(4...)
            .autocapitalization(.sentences)
            .accessibilityIdentifier("SendUserFeedbackView.FeedbackContentField.TextField")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    // MARK: - Send

    @ViewBuilder private func SendButton() -> some View {
        TaskAwareButton(
            buttonColor: .brandTeal,
            contentColor: .appBackground
        ) {
            await sendFeedback()
        } label: {
            HStack(spacing: .paddingSmall) {
                Image(systemName: "paperplane.fill")
                Text("Send")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("SendUserFeedbackView.SendButton")
    }
}

#Preview {
    NavigationStack {
        SendUserFeedbackView(
            currentUserIdProvider: MockCurrentUserIdProvider(),
            feedbackSender: MockFeedbackSender()
        )
    }
}
