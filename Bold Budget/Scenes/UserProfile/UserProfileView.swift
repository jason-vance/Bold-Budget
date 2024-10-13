//
//  UserProfileView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/11/24.
//

import SwiftUI
import SwinjectAutoregistration
import _AuthenticationServices_SwiftUI

struct UserProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var userIdState: UserId?
    
    @State private var showSignOutDialog: Bool = false
    @State private var showDeleteAccountDialog: Bool = false
    @State private var showConfirmDeleteAccountSheet: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    public let userId: UserId
    
    private let signOutService: UserSignOutService
    private let accountDeleter: UserAccountDeleter

    init(
        userId: UserId
    ) {
        self.init(
            userId: userId,
            signOutService: iocContainer~>UserSignOutService.self,
            accountDeleter: iocContainer~>UserAccountDeleter.self
        )
    }
    
    init(
        userId: UserId,
        signOutService: UserSignOutService,
        accountDeleter: UserAccountDeleter
    ) {
        self.userId = userId
        self.signOutService = signOutService
        self.accountDeleter = accountDeleter
    }
    
    private func confirmedSignOut() {
        do {
            try signOutService.signOut()
        } catch {
            show(alert: "Could not sign out. \(error.localizedDescription)")
        }
    }
    
    private func confirmDeleteAccount() {
        showConfirmDeleteAccountSheet = true
    }
    
    private func actuallyDeleteAccount(authResult: Result<ASAuthorization, Error>) {
        showConfirmDeleteAccountSheet = false
        Task {
            do {
                switch authResult {
                case .success(let authorization):
                    try await accountDeleter.deleteUser(authorization: authorization)
                case .failure(let error):
                    throw error
                }
            } catch {
                let errorMessage = "Account could not be deleted: \(error.localizedDescription)"
                print(errorMessage)
                show(alert: errorMessage)
            }
        }
    }
    
    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ProfileImage()
                Spacer(minLength: 0)
                SignOutButton()
                    .padding(.horizontal)
                DeleteAccountButton()
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
    
    @ViewBuilder private func ProfileImage() -> some View {
        //TODO: Get profile image url
        ProfileImageView(nil)
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
    
    @ViewBuilder func DeleteAccountButton() -> some View {
        Button {
            showDeleteAccountDialog = true
        } label: {
            Text("Delete Account")
                .frame(maxWidth: .infinity)
                .buttonLabelMedium()
        }
        .accessibilityIdentifier("UserProfileView.DeleteAccountButton")
        .listRowBackground(Color.background)
        .confirmationDialog(
            "Are you sure you want to delete your account?",
            isPresented: $showDeleteAccountDialog,
            titleVisibility: .visible
        ) {
            ConfirmDeleteAccountButton()
            CancelDeleteAccountButton()
        }
        .sheet(isPresented: $showConfirmDeleteAccountSheet) {
            ConfirmDeleteAccountSheet()
        }
    }
    
    @ViewBuilder func ConfirmDeleteAccountSheet() -> some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [.clear, .text], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .onTapGesture {
                    showConfirmDeleteAccountSheet = false
                }
            VStack {
                Text("Are you really sure you want to delete your account? This action will delete all of your data and is irreversible.")
                    .foregroundStyle(Color.text)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                ReallyConfirmDeleteAccountButton()
                CancelDeleteAccountButton()
            }
            .padding()
            .background(Color.background)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous))
            .padding()
        }
        .presentationCompactAdaptation(.fullScreenCover)
        .presentationBackground(.clear)
    }
    
    @ViewBuilder func ReallyConfirmDeleteAccountButton() -> some View {
        SignInWithAppleButton(.continue) { _ in
        } onCompletion: { result in
            actuallyDeleteAccount(authResult: result)
        }
        .accessibilityIdentifier("UserProfileView.ReallyConfirmDeleteAccountButton")
        .frame(height: 48)
        .padding(.vertical)
    }
    
    @ViewBuilder func ConfirmDeleteAccountButton() -> some View {
        Button(role: .destructive) {
            confirmDeleteAccount()
        } label: {
            Text("Delete Account")
        }
        .accessibilityIdentifier("UserProfileView.ConfirmDeleteAccountButton")
    }
    
    @ViewBuilder func CancelDeleteAccountButton() -> some View {
        Button(role: .cancel) {
            showDeleteAccountDialog = false
            showConfirmDeleteAccountSheet = false
        } label: {
            Text("Cancel")
        }
        .accessibilityIdentifier("UserProfileView.CancelDeleteAccountButton")
        .frame(height: 48)
    }
}

#Preview {
    UserProfileView(
        userId: .sample,
        signOutService: MockUserSignOutService(),
        accountDeleter: MockUserAccountDeleter()
    )
}
