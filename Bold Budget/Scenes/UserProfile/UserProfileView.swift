//
//  UserProfileView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/11/24.
//

import SwiftUI
import SwinjectAutoregistration

struct UserProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var userIdState: UserId?
    
    @State private var showSignOutDialog: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    public let userId: UserId
    
    private let signOutService: UserSignOutService
    
    init(
        userId: UserId
    ) {
        self.init(
            userId: userId,
            signOutService: iocContainer~>UserSignOutService.self
        )
    }
    
    init(
        userId: UserId,
        signOutService: UserSignOutService
    ) {
        self.userId = userId
        self.signOutService = signOutService
    }
    
    private func confirmedSignOut() {
        do {
            try signOutService.signOut()
        } catch {
            show(alert: "Could not sign out. \(error.localizedDescription)")
        }
    }
    
    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer(minLength: 0)
                SignOutButton()
                    .padding(.horizontal)
            }
            .toolbar { Toolbar() }
            .foregroundStyle(Color.text)
            .background(Color.background)
        }
        .onChange(of: userId, initial: true) { _, userId in userIdState = userId }
        .alert(alertMessage, isPresented: $showAlert) {}
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityIdentifier("UserProfileView.Toolbar.DismissButton")
        }
        ToolbarItemGroup(placement: .principal) {
            Text(userId.value)
                .font(.body.bold())
        }
    }
    
    @ViewBuilder private func SignOutButton() -> some View {
        Button {
            showSignOutDialog = true
        } label: {
            Text("Logout")
                .frame(maxWidth: .infinity)
                .buttonLabelMedium(isProminent: true)
        }
        .accessibilityIdentifier("UserProfileView.SignOutButton")
        .confirmationDialog(
            "Are you sure you want to sign out?",
            isPresented: $showSignOutDialog,
            titleVisibility: .visible
        ) {
            ConfirmSignOutButton()
            CancelSignOutButton()
        }
    }
    
    @ViewBuilder func ConfirmSignOutButton() -> some View {
        Button(role: .destructive) {
            confirmedSignOut()
        } label: {
            Text("Sign Out")
        }
        .accessibilityIdentifier("UserProfileView.ConfirmSignOutButton")
    }
    
    @ViewBuilder func CancelSignOutButton() -> some View {
        Button(role: .cancel) {
        } label: {
            Text("Cancel")
        }
        .accessibilityIdentifier("UserProfileView.CancelSignOutButton")
    }
}

#Preview {
    UserProfileView(
        userId: .sample,
        signOutService: MockUserSignOutService()
    )
}
