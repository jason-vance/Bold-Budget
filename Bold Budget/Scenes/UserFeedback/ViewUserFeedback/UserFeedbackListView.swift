//
//  UserFeedbackListView.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/5/25.
//

import SwiftUI
import SwinjectAutoregistration

/// Admin screen listing unresolved user feedback in the redesign palette: a self-contained header
/// (back button + centered title), a scrolling card of feedback rows, an empty state, and pull-to-
/// refresh. Self-contained (own header + scroll) so it carries the redesign look without the shared
/// List chrome, mirroring `BudgetsListView`.
struct UserFeedbackListView: View {

    @Environment(\.dismiss) private var dismiss: DismissAction

    @State private var userFeedbacks: [UserFeedback]?

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private let feedbackFetcher: UserFeedbackFetcher

    private var sortedFeedback: [UserFeedback] {
        guard let userFeedbacks else { return [] }
        return userFeedbacks.sorted { $0.date < $1.date }
    }

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
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(spacing: .padding) {
                    if let userFeedbacks = userFeedbacks {
                        if userFeedbacks.isEmpty {
                            EmptyState()
                        } else {
                            FeedbackCard()
                        }
                    } else {
                        BlockingSpinnerView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, .padding * 2)
                    }
                }
                .animation(.snappy, value: userFeedbacks)
                .padding()
            }
            .scrollIndicators(.hidden)
            .refreshable { fetchUserFeedback() }
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .alert(alertMessage, isPresented: $showAlert) {}
        .onAppear { fetchUserFeedback() }
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text("User Feedback")
                .font(.headline)
                .foregroundStyle(Color.appText)
                .padding(.horizontal, .barHeight)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                }
                .accessibilityIdentifier("UserFeedbackListView.DismissButton")
                Spacer(minLength: 0)
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Feedback

    @ViewBuilder private func FeedbackCard() -> some View {
        VStack(spacing: 0) {
            ForEach(Array(sortedFeedback.enumerated()), id: \.element.id) { index, feedback in
                if index > 0 { RowDivider() }
                FeedbackRow(feedback)
            }
        }
        .card(0)
    }

    @ViewBuilder private func FeedbackRow(_ feedback: UserFeedback) -> some View {
        NavigationLink {
            UserFeedbackDetailView(feedback: feedback)
        } label: {
            HStack(spacing: .padding) {
                IconCircle(systemName: "text.bubble.fill", size: 40, tint: .brandTeal)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(feedback.userId.value)
                            .lineLimit(1)
                        Spacer(minLength: .paddingSmall)
                        Text(feedback.date.toBasicUiString())
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.appMutedText)
                    Text(feedback.content.value)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color.appText)
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appMutedText)
            }
            .padding(.padding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("UserFeedbackListView.FeedbackRow.\(feedback.id)")
    }

    @ViewBuilder private func RowDivider(opacity: Double = 0.15) -> some View {
        Rectangle()
            .fill(Color.appMutedText.opacity(opacity))
            .frame(height: 1)
            .padding(.leading, .padding)
    }

    // MARK: - Empty state

    @ViewBuilder private func EmptyState() -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(systemName: "square.dashed", size: 56, tint: .brandTeal)
            Text("No User Feedback")
                .font(.title3.weight(.bold))
            Text("There is currently no unresolved user feedback.")
                .font(.subheadline)
                .foregroundStyle(Color.appMutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .padding * 2)
    }
}

#Preview {
    NavigationStack {
        UserFeedbackListView(
            feedbackFetcher: MockUserFeedbackFetcher(feedback: [.sample])
        )
    }
}

#Preview("No feedback") {
    NavigationStack {
        UserFeedbackListView(
            feedbackFetcher: MockUserFeedbackFetcher(feedback: [])
        )
    }
}
