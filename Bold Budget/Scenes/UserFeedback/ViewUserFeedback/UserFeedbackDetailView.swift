//
//  UserFeedbackDetailView.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/5/25.
//

import SwiftUI
import SwinjectAutoregistration

struct UserFeedbackDetailView: View {
    
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
        self.feedback = feedback
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
        List {
            UserSection()
            MetadataSection()
            ContentSection()
        }
        .animation(.snappy, value: userData)
        .animation(.snappy, value: isUpdatingStatus)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Feedback Detail")
        .foregroundStyle(Color.text)
        .background(Color.background)
        .alert(alertMessage, isPresented: $showAlert) {}
        .onAppear { fetchUserData() }
    }
    
    @ViewBuilder private func UserSection() -> some View {
        if let userData {
            Section {
                UserRow(user: userData)
            } header: {
                Text("User")
            }
        }
    }
    
    @ViewBuilder private func UserRow(user: UserData) -> some View {
        HStack {
            ProfileImageView(
                user.profileImageUrl,
                size: 32,
                padding: .borderWidthThin
            )
            if let username = user.username {
                Text(username.value)
            }
            Spacer(minLength: 0)
        }
        .listRow()
    }
    
    @ViewBuilder private func MetadataSection() -> some View {
        Section {
            StatusRow()
            HStack {
                Text("Date:")
                Spacer()
                Text(feedback.date.formatted())
            }
            .listRow()
            HStack {
                Text("Version:")
                Spacer()
                Text(feedback.appVersion)
            }
            .listRow()
        } header: {
            Text("Metadata")
        }
    }
    
    @ViewBuilder private func StatusRow() -> some View {
        HStack {
            Text("Status:")
            Spacer()
            StatusMenu()
        }
        .listRow()
    }
    
    @ViewBuilder private func StatusMenu() -> some View {
        if isUpdatingStatus {
            ProgressView()
                .progressViewStyle(.circular)
        } else {
            Menu {
                ForEach(UserFeedback.Status.allCases, id: \.self) { status in
                    Button() {
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
                    .buttonLabelSmall()
            }
        }
    }
    
    @ViewBuilder private func ContentSection() -> some View {
        Section {
            Text(feedback.content.value)
                .listRow()
        } header: {
            Text("Feedback")
        }
    }
}

#Preview {
    UserFeedbackDetailView(
        feedback: .sample,
        userDataFetcher: MockUserDataFetcher(),
        feedbackResolver: MockUserFeedbackResolver()
    )
}
