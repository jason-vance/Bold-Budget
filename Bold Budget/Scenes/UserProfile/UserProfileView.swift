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
    
    @State private var userId: UserId?
    @State private var userData: UserData?
    
    @State private var showAdminControls: Bool = false
    @State private var subscriptionLevel: SubscriptionLevel = .none
    
    @State private var showEditUserProfile: Bool = false
    @State private var showSignOutDialog: Bool = false
    @State private var showDeleteAccountDialog: Bool = false
    @State private var showConfirmDeleteAccountSheet: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    private let __userId: UserId
    
    private let currentUserIdProvider: CurrentUserIdProvider
    private let isAdminChecker: IsAdminChecker
    private let subscriptionLevelProvider: SubscriptionLevelProvider
    private let userDataProvider: UserDataProvider
    private let signOutService: UserSignOutService
    private let accountDeleter: UserAccountDeleter
    
    private var isMe: Bool { currentUserIdProvider.currentUserId == userId }
    
    private func checkIsAdmin() {
        guard let userId = currentUserIdProvider.currentUserId else { return }
        
        Task {
            do {
                showAdminControls = try await isAdminChecker.isAdmin(userId: userId)
            } catch {
                print("Could not check if user is admin. \(error.localizedDescription)")
            }
        }
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
    
    init(
        userId: UserId
    ) {
        self.init(
            userId: userId,
            currentUserIdProvider: iocContainer~>CurrentUserIdProvider.self,
            isAdminChecker: iocContainer~>IsAdminChecker.self,
            subscriptionLevelProvider: iocContainer~>SubscriptionLevelProvider.self,
            userDataProvider: iocContainer~>UserDataProvider.self,
            signOutService: iocContainer~>UserSignOutService.self,
            accountDeleter: iocContainer~>UserAccountDeleter.self
        )
    }
    
    init(
        userId: UserId,
        currentUserIdProvider: CurrentUserIdProvider,
        isAdminChecker: IsAdminChecker,
        subscriptionLevelProvider: SubscriptionLevelProvider,
        userDataProvider: UserDataProvider,
        signOutService: UserSignOutService,
        accountDeleter: UserAccountDeleter
    ) {
        self.__userId = userId
        self.currentUserIdProvider = currentUserIdProvider
        self.isAdminChecker = isAdminChecker
        self.subscriptionLevelProvider = subscriptionLevelProvider
        self.userDataProvider = userDataProvider
        self.signOutService = signOutService
        self.accountDeleter = accountDeleter
    }
    
    var body: some View {
        List {
            ProfileImageSection()
            EditUserProfileSection()
            FeedbackSection()
            SignOutDeleteAccountSection()
            AppVersionSection()
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .toolbar { Toolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(userData?.username?.value ?? "User Profile")
        .navigationBarBackButtonHidden()
        .foregroundStyle(Color.text)
        .background(Color.background)
        .onChange(of: __userId, initial: true) { _, userId in self.userId = userId }
        .onChange(of: __userId, initial: true) { _, userId in userDataProvider.startListeningToUser(withId: userId) }
        .onReceive(userDataProvider.userDataPublisher) { userData = $0 }
        .alert(alertMessage, isPresented: $showAlert) {}
        .onDisappear { userDataProvider.stopListeningToUser() }
        .onReceive(subscriptionLevelProvider.subscriptionLevelPublisher) { subscriptionLevel = $0 }
        .onAppear { checkIsAdmin() }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.backward")
            }
            .accessibilityIdentifier("UserProfileView.Toolbar.DismissButton")
        }
    }
    
    @ViewBuilder private func ProfileImageSection() -> some View {
        Section {
            ProfileImage()
        }
    }
    
    @ViewBuilder private func ProfileImage() -> some View {
        HStack {
            Spacer(minLength: 0)
            ProfileImageView(userData?.profileImageUrl)
            Spacer(minLength: 0)
        }
        .listRowBackground(Color.background)
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder private func EditUserProfileSection() -> some View {
        if isMe {
            Section {
                EditUserProfileButton()
                if showAdminControls {
                    ChangeSubscriptionLevelButton()
                }
            }
        }
    }
    
    @ViewBuilder private func EditUserProfileButton() -> some View {
        Button {
            showEditUserProfile = true
        } label: {
            HStack {
                Image(systemName: "person")
                    .listRowIcon()
                Text("Edit User Profile")
                Spacer(minLength: 0)
            }
        }
        .listRow()
        .fullScreenCover(isPresented: $showEditUserProfile) {
            NavigationStack {
                EditUserProfileView(mode: .editProfile)
            }
        }
    }
    
    @ViewBuilder private func ChangeSubscriptionLevelButton() -> some View {
        HStack {
            Image(systemName: "dollarsign")
                .listRowIcon()
            Text("Subscription Level")
            Spacer()
            Menu {
                Button("None") {
                    subscriptionLevelProvider.set(subscriptionLevel: .none)
                }
                Button("Bold Budget+") {
                    subscriptionLevelProvider.set(subscriptionLevel: .boldBudgetPlus)
                }
            } label: {
                Text(String(describing: subscriptionLevel))
                    .foregroundStyle(Color.text)
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
                    .padding(.vertical, .paddingVerticalButtonXSmall)
                    .background {
                        RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                            .foregroundStyle(Color.text)
                            .opacity(.opacityButtonBackground)
                    }
            }
        }
        .listRow()
    }
    
    @ViewBuilder private func FeedbackSection() -> some View {
        Section {
            SubmitFeedbackButton()
        }
    }
    
    @ViewBuilder private func SubmitFeedbackButton() -> some View {
        NavigationLink {
            UserFeedbackView()
        } label: {
            HStack {
                Image(systemName: "envelope")
                    .listRowIcon()
                Text("Submit Feedback")
                Spacer(minLength: 0)
            }
        }
        .listRow()
        .accessibilityIdentifier("UserProfileView.SubmitFeedbackButton")
    }
    
    @ViewBuilder private func SignOutDeleteAccountSection() -> some View {
        if isMe {
            Section {
                SignOutButton()
                DeleteAccountButton()
            }
        }
    }
    
    @ViewBuilder private func SignOutButton() -> some View {
        Button {
            showSignOutDialog = true
        } label: {
            HStack {
                Image(systemName: "iphone.and.arrow.forward")
                    .listRowIcon()
                Text("Sign Out")
                Spacer(minLength: 0)
            }
        }
        .listRow()
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
            HStack {
                Image(systemName: "trash")
                    .listRowIcon()
                Text("Delete Account")
                Spacer(minLength: 0)
            }
        }
        .listRow()
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
    
    @ViewBuilder private func AppVersionSection() -> some View {
        Section {
            HStack {
                Spacer()
                Text("Version:")
                Text("\(AppInfo.versionString)(\(AppInfo.buildNumberString))")
                Spacer()
            }
            .foregroundStyle(Color.text.opacity(.opacityMutedText))
            .listRowNoChrome()
        }
    }
}

#Preview("Mine") {
    NavigationStack {
        UserProfileView(
            userId: .sample,
            currentUserIdProvider: MockCurrentUserIdProvider(),
            isAdminChecker: MockIsAdminChecker(),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .none),
            userDataProvider: MockUserDataProvider(),
            signOutService: MockUserSignOutService(),
            accountDeleter: MockUserAccountDeleter()
        )
    }
}

#Preview("Other's") {
    NavigationStack {
        UserProfileView(
            userId: .init(UUID().uuidString)!,
            currentUserIdProvider: MockCurrentUserIdProvider(),
            isAdminChecker: MockIsAdminChecker(),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .none),
            userDataProvider: MockUserDataProvider(),
            signOutService: MockUserSignOutService(),
            accountDeleter: MockUserAccountDeleter()
        )
    }
}
