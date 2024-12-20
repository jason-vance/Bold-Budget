//
//  UserFeedbackView.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/17/24.
//

import SwiftUI
import MessageUI
import SwinjectAutoregistration

struct UserFeedbackView: View {
    
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
    
    private var feedback: Feedback? {
        guard let userId = currentUserId else { return nil }
        guard let content = Feedback.Content.init(feedbackString) else { return nil }
        
        return .init(
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
        if feedbackString.count < Feedback.Content.minTextLength { return "Too short" }
        if feedbackString.count > Feedback.Content.maxTextLength { return "Too long" }
        return "\(feedbackString.count)/\(Feedback.Content.maxTextLength)"
    }
    
    var body: some View {
        Form {
            Section {
                FeedbackContentField()
            }
            Section {
                SendButton()
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) { //this will push the view farther when the keyboard is shown
            Color.clear.frame(height: 100)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Submit Feedback")
        .foregroundStyle(Color.text)
        .background(Color.background)
        .alert(alertMessage, isPresented: $showAlert) {}
    }
    
    @ViewBuilder func FeedbackContentField() -> some View {
        VStack {
            HStack {
                Text("Your Feedback")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                Text(feedbackInstructions)
                    .font(.caption2)
                    .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
                    .animation(.snappy, value: feedbackInstructions)
            }
            TextField("Feedback",
                      text: $feedbackString,
                      prompt: Text("What do you think about Bold Budget?").foregroundStyle(Color.text.opacity(.opacityTextFieldPrompt)),
                      axis: .vertical
            )
            .textFieldSmall()
            .autocapitalization(.sentences)
            .accessibilityIdentifier("UserFeedbackView.FeedbackContentField.TextField")
        }
        .formRow()
    }
    
    @ViewBuilder private func SendButton() -> some View {
        HStack {
            Spacer()
            TaskAwareButton {
                await sendFeedback()
            } label: {
                HStack {
                    Image(systemName: "paperplane")
                    Text("Send")
                }
                .foregroundStyle(Color.background)
            }
        }
        .listRowNoChrome()
    }
}

#Preview {
    UserFeedbackView(
        currentUserIdProvider: MockCurrentUserIdProvider(),
        feedbackSender: MockFeedbackSender()
    )
}
