//
//  UserFeedbackListView.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/5/25.
//

import SwiftUI
import SwinjectAutoregistration

struct UserFeedbackListView: View {
    
    @State private var userFeedbacks: [UserFeedback]?
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    private let feedbackFetcher: UserFeedbackFetcher
    
    init() {
        self.init(
            feedbackFetcher: iocContainer~>UserFeedbackFetcher.self
        )
    }

    init(
        feedbackFetcher: UserFeedbackFetcher
    ) {
        self.feedbackFetcher = feedbackFetcher
    }

    private func fetchUserFeedback() {
        Task {
            do {
                userFeedbacks = try await feedbackFetcher.fetchUnresolvedUserFeedback()
            } catch {
                show(alert: "Feedback could not be fetched. \(error.localizedDescription)")
            }
        }
    }
    
    private func show(alert message: String) {
        showAlert = true
        alertMessage = message
    }
    
    var body: some View {
        List {
            if let userFeedbacks = userFeedbacks {
                if userFeedbacks.isEmpty {
                    NoFeedbackSection()
                } else {
                    FeedbackSection(userFeedbacks)
                }
            } else {
                BlockingSpinnerView()
                    .listRowNoChrome()
            }
        }
        .animation(.snappy, value: userFeedbacks)
        .refreshable { fetchUserFeedback() }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("User Feedback")
        .foregroundStyle(Color.text)
        .background(Color.background)
        .alert(alertMessage, isPresented: $showAlert) {}
        .onAppear { fetchUserFeedback() }
    }
    
    @ViewBuilder private func NoFeedbackSection() -> some View {
        Section {
            ContentUnavailableView(
                "No User Feedback",
                systemImage: "square.dashed",
                description: Text("There is currently no unresolved user feedback")
            )
            .listRowNoChrome()
        }
    }
    
    @ViewBuilder private func FeedbackSection(_ feedbacks: [UserFeedback]) -> some View {
        Section {
            ForEach(feedbacks) { feedback in
                FeedbackRow(feedback)
            }
        }
    }
    
    @ViewBuilder private func FeedbackRow(_ feedback: UserFeedback) -> some View {
        NavigationLink {
            UserFeedbackDetailView(feedback: feedback)
        } label: {
            VStack {
                HStack {
                    Text(feedback.userId.value)
                    Spacer(minLength: 0)
                    Text(feedback.date.toBasicUiString())
                }
                .font(.footnote.bold())
                .opacity(.opacityMutedText)
                HStack {
                    Text(feedback.content.value)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
            }
        }
        .listRow()
        .accessibilityIdentifier("UserFeedbackListView.FeedbackRow.\(feedback.id)")
    }
}

#Preview {
    UserFeedbackListView(
        feedbackFetcher: MockUserFeedbackFetcher(feedback: [.sample])
    )
}
