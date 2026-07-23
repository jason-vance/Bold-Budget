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
    
    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?
    
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
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(spacing: .padding) {
                    Profile()
                    AdCard()
                    AdminCard()
                    ActionsCard()
                    SignOutButton()
                    DeleteAccountButton()
                    AppVersion()
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .onChange(of: __userId, initial: true) { _, userId in self.userId = userId }
        .onChange(of: __userId, initial: true) { _, userId in userDataProvider.startListeningToUser(withId: userId) }
        .onReceive(userDataProvider.userDataPublisher) { userData = $0 }
        .alert(alertMessage, isPresented: $showAlert) {}
        .onDisappear { userDataProvider.stopListeningToUser() }
        .onReceive(subscriptionLevelProvider.subscriptionLevelPublisher) { subscriptionLevel = $0 }
        .onAppear { checkIsAdmin() }
        .animation(.snappy, value: showAdminControls)
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text(userData?.username?.value ?? "User Profile")
                .font(.headline)
                .foregroundStyle(Color.appText)
                .lineLimit(1)
                .padding(.horizontal, .barHeight)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                }
                .accessibilityIdentifier("UserProfileView.Toolbar.DismissButton")
                Spacer(minLength: 0)
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Profile

    @ViewBuilder private func Profile() -> some View {
        VStack(spacing: .paddingSmall) {
            ProfileImageView(userData?.profileImageUrl, size: 120)
            if let username = userData?.username {
                Text(username.value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, .paddingSmall)
    }

    // MARK: - Ad

    @ViewBuilder private func AdCard() -> some View {
        if subscriptionLevel == SubscriptionLevel.none {
            NativeAdListRow(ad: $ad, size: .small)
                .frame(maxWidth: .infinity)
                .card()
        }
    }

    // MARK: - Row building blocks

    @ViewBuilder private func NavRow(systemName: String, title: LocalizedStringKey, tint: Color = .brandTeal) -> some View {
        HStack(spacing: .padding) {
            IconCircle(systemName: systemName, size: 40, tint: tint)
            Text(title)
                .fontWeight(.semibold)
                .foregroundStyle(Color.appText)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appMutedText)
        }
        .padding(.padding)
        .contentShape(Rectangle())
    }

    @ViewBuilder private func RowDivider(opacity: Double = 0.15) -> some View {
        Rectangle()
            .fill(Color.appMutedText.opacity(opacity))
            .frame(height: 1)
            .padding(.leading, .padding)
    }

    // MARK: - Admin

    @ViewBuilder private func AdminCard() -> some View {
        if showAdminControls {
            VStack(alignment: .leading, spacing: .paddingSmall) {
                Text("Admin")
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .kerning(0.5)
                    .foregroundStyle(Color.appMutedText)
                    .padding(.horizontal, .paddingSmall)
                VStack(spacing: 0) {
                    ChangeSubscriptionLevelRow()
                    RowDivider()
                    ViewUserFeedbackButton()
                }
                .card(0)
            }
        }
    }

    @ViewBuilder private func ChangeSubscriptionLevelRow() -> some View {
        HStack(spacing: .padding) {
            IconCircle(systemName: "dollarsign", size: 40, tint: .brandTeal)
            Text("Subscription Level")
                .fontWeight(.semibold)
                .foregroundStyle(Color.appText)
            Spacer(minLength: 0)
            Menu {
                Button("None") {
                    subscriptionLevelProvider.set(subscriptionLevel: .none)
                }
                Button("Bold Budget+") {
                    subscriptionLevelProvider.set(subscriptionLevel: .boldBudgetPlus)
                }
            } label: {
                Text(String(describing: subscriptionLevel))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appText)
                    .padding(.horizontal, .paddingHorizontalButtonSmall)
                    .padding(.vertical, .paddingVerticalButtonXSmall)
                    .background { Capsule().foregroundStyle(Color.appSurface) }
            }
        }
        .padding(.padding)
    }

    @ViewBuilder private func ViewUserFeedbackButton() -> some View {
        NavigationLink {
            UserFeedbackListView()
        } label: {
            NavRow(systemName: "envelope", title: "View User Feedback")
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("UserProfileView.ViewUserFeedbackButton")
    }

    // MARK: - Actions

    @ViewBuilder private func ActionsCard() -> some View {
        VStack(spacing: 0) {
            if isMe {
                EditUserProfileButton()
                RowDivider()
            }
            SubmitFeedbackButton()
        }
        .card(0)
    }

    @ViewBuilder private func EditUserProfileButton() -> some View {
        Button {
            showEditUserProfile = true
        } label: {
            NavRow(systemName: "person", title: "Edit User Profile")
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showEditUserProfile) {
            NavigationStack {
                EditUserProfileView(mode: .editProfile)
            }
        }
    }

    @ViewBuilder private func SubmitFeedbackButton() -> some View {
        NavigationLink {
            SendUserFeedbackView()
        } label: {
            NavRow(systemName: "envelope", title: "Submit Feedback")
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("UserProfileView.SubmitFeedbackButton")
    }

    // MARK: - Sign Out / Delete

    @ViewBuilder private func SignOutButton() -> some View {
        if isMe {
            Button {
                showSignOutDialog = true
            } label: {
                HStack(spacing: .paddingSmall) {
                    Image(systemName: "iphone.and.arrow.forward")
                    Text("Sign Out")
                }
                .font(.headline)
                .foregroundStyle(Color.appText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .paddingVerticalButtonMedium)
                .background {
                    RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                        .foregroundStyle(Color.appSurface)
                }
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
        if isMe {
            Button {
                showDeleteAccountDialog = true
            } label: {
                HStack(spacing: .paddingSmall) {
                    Image(systemName: "trash")
                    Text("Delete Account")
                }
                .font(.headline)
                .foregroundStyle(Color.negative)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .paddingVerticalButtonMedium)
                .background {
                    RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                        .foregroundStyle(Color.appSurface)
                }
            }
            .accessibilityIdentifier("UserProfileView.DeleteAccountButton")
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
    
    @ViewBuilder private func AppVersion() -> some View {
        HStack(spacing: .paddingSmall) {
            Text("Version:")
            Text("\(AppInfo.versionString)(\(AppInfo.buildNumberString))")
        }
        .font(.footnote)
        .foregroundStyle(Color.appMutedText)
        .frame(maxWidth: .infinity)
        .padding(.top, .paddingSmall)
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
    .environmentObject(AdProviderFactory.forScreenshots)
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
    .environmentObject(AdProviderFactory.forScreenshots)
}
