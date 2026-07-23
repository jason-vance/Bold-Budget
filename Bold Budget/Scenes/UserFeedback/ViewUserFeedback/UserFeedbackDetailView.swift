//
//  UserFeedbackDetailView.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/5/25.
//

import SwiftUI
import SwinjectAutoregistration

/// Admin detail screen for a single piece of user feedback in the redesign palette: a self-contained
/// header (back button + centered title) over scrolling cards for the user, metadata (status menu,
/// date, version), and the feedback content. Mirrors `UserProfileView`'s self-contained redesign look.
struct UserFeedbackDetailView: View {

    @Environment(\.dismiss) private var dismiss: DismissAction

    @State private var feedback: UserFeedback
    @State private var userData: UserData?

    @State private var isUpdatingStatus: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    let userDataFetcher: UserDataFetcher
    let feedbackResolver: UserFeedbackResolver

    init(feedback: UserFeedback) {
        self.init(
            feedback: feedback,
            userDataFetcher: iocContainer~>UserDataFetcher.self,
            feedbackResolver: iocContainer~>UserFeedbackResolver.self
        )
    }

    init(
        feedback: UserFeedback,
        userDataFetcher: UserDataFetcher,
        feedbackResolver: UserFeedbackResolver
    ) {
        self._feedback = State(initialValue: feedback)
        self.userDataFetcher = userDataFetcher
        self.feedbackResolver = feedbackResolver
    }

    private func fetchUserData() {
        Task {
            do {
                userData = try await userDataFetcher.fetchUserData(withId: feedback.userId)
            } catch {
                show(alert: "UserData could not be fetched. \(error.localizedDescription)")
            }
        }
    }

    private func update(status: UserFeedback.Status) {
        isUpdatingStatus = true

        Task {
            do {
                let updatedFeedback = feedback.with(status: status)
                try await feedbackResolver.updateStatus(of: updatedFeedback)
                feedback = updatedFeedback
            } catch {
                show(alert: "Failed to update status of feedback: \(error.localizedDescription)")
            }

            isUpdatingStatus = false
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
                    UserCard()
                    MetadataCard()
                    ContentCard()
                }
                .animation(.snappy, value: userData)
                .animation(.snappy, value: isUpdatingStatus)
                .animation(.snappy, value: feedback)
                .padding()
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .alert(alertMessage, isPresented: $showAlert) {}
        .onAppear { fetchUserData() }
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text("Feedback Detail")
                .font(.headline)
                .foregroundStyle(Color.appText)
                .padding(.horizontal, .barHeight)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                }
                .accessibilityIdentifier("UserFeedbackDetailView.DismissButton")
                Spacer(minLength: 0)
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Section building blocks

    @ViewBuilder private func SectionLabel(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .kerning(0.5)
            .foregroundStyle(Color.appMutedText)
            .padding(.horizontal, .paddingSmall)
    }

    @ViewBuilder private func RowDivider(opacity: Double = 0.15) -> some View {
        Rectangle()
            .fill(Color.appMutedText.opacity(opacity))
            .frame(height: 1)
    }

    // MARK: - User

    @ViewBuilder private func UserCard() -> some View {
        if let userData {
            VStack(alignment: .leading, spacing: .paddingSmall) {
                SectionLabel("User")
                HStack(spacing: .padding) {
                    ProfileImageView(userData.profileImageUrl, size: 40)
                    if let username = userData.username {
                        Text(username.value)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.appText)
                    }
                    Spacer(minLength: 0)
                }
                .card()
            }
        }
    }

    // MARK: - Metadata

    @ViewBuilder private func MetadataCard() -> some View {
        VStack(alignment: .leading, spacing: .paddingSmall) {
            SectionLabel("Metadata")
            VStack(spacing: .padding) {
                StatusRow()
                RowDivider()
                MetadataRow(label: "Date", value: feedback.date.formatted())
                RowDivider()
                MetadataRow(label: "Version", value: feedback.appVersion)
            }
            .card()
        }
    }

    @ViewBuilder private func MetadataRow(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Color.appMutedText)
            Spacer(minLength: .paddingSmall)
            Text(value)
                .foregroundStyle(Color.appText)
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder private func StatusRow() -> some View {
        HStack {
            Text("Status")
                .foregroundStyle(Color.appMutedText)
            Spacer(minLength: .paddingSmall)
            StatusMenu()
        }
    }

    @ViewBuilder private func StatusMenu() -> some View {
        if isUpdatingStatus {
            ProgressView()
                .progressViewStyle(.circular)
        } else {
            Menu {
                ForEach(UserFeedback.Status.allCases, id: \.self) { status in
                    Button {
                        update(status: status)
                    } label: {
                        HStack {
                            Text(status.rawValue)
                            if status == feedback.status {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Text(feedback.status.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appText)
                    .padding(.horizontal, .paddingHorizontalButtonSmall)
                    .padding(.vertical, .paddingVerticalButtonXSmall)
                    .background { Capsule().foregroundStyle(Color.appSurface) }
            }
            .accessibilityIdentifier("UserFeedbackDetailView.StatusMenu")
        }
    }

    // MARK: - Content

    @ViewBuilder private func ContentCard() -> some View {
        VStack(alignment: .leading, spacing: .paddingSmall) {
            SectionLabel("Feedback")
            HStack {
                Text(feedback.content.value)
                    .foregroundStyle(Color.appText)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .card()
        }
    }
}

#Preview {
    NavigationStack {
        UserFeedbackDetailView(
            feedback: .sample,
            userDataFetcher: MockUserDataFetcher(),
            feedbackResolver: MockUserFeedbackResolver()
        )
    }
}
