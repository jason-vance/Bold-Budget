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
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    let userDataFetcher: UserDataFetcher
    
    init(feedback: UserFeedback) {
        self.init(
            feedback: feedback,
            userDataFetcher: iocContainer~>UserDataFetcher.self
        )
    }
    
    init(
        feedback: UserFeedback,
        userDataFetcher: UserDataFetcher
    ) {
        self.feedback = feedback
        self.userDataFetcher = userDataFetcher
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
        userDataFetcher: MockUserDataFetcher()
    )
}
