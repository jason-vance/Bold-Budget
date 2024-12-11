//
//  EditUserProfileView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import Combine
import MarkdownUI
import SwiftUI
import SwinjectAutoregistration

struct EditUserProfileView: View {
    
    enum Mode {
        case createProfile
        case editProfile
    }
    
    private enum InitializationState {
        case notInitialized
        case initialized
    }
    
    private let currentUserIdProvider: CurrentUserIdProvider
    private let userDataFetcher: UserDataFetcher
    private let imageUploader: ProfileImageUploader
    private let userDataSaver: UserDataSaver
    
    var mode: Mode
    
    @Environment(\.dismiss) private var dismiss: DismissAction
    
    @State private var profileImage: UIImage = .init()
    @State private var profileImageUrl: URL? = nil
    @State private var username: Username? = nil
    @State private var termsOfServiceAcceptance: Date? = nil
    @State private var privacyPolicyAcceptance: Date? = nil
    @State private var initializationState: InitializationState = .notInitialized

    @State private var showTermsOfService: Bool = false
    @State private var showPrivacyPolicy: Bool = false
    @State private var showBlockingSpinner: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    init(
        mode: Mode
    ) {
        self.init(
            mode: mode,
            currentUserIdProvider: iocContainer~>CurrentUserIdProvider.self,
            userDataFetcher: iocContainer~>UserDataFetcher.self,
            imageUploader: iocContainer~>ProfileImageUploader.self,
            userDataSaver: iocContainer~>UserDataSaver.self
        )
    }
    
    init(
        mode: Mode,
        currentUserIdProvider: CurrentUserIdProvider,
        userDataFetcher: UserDataFetcher,
        imageUploader: ProfileImageUploader,
        userDataSaver: UserDataSaver
    ) {
        self.mode = mode
        self.currentUserIdProvider = currentUserIdProvider
        self.userDataFetcher = userDataFetcher
        self.imageUploader = imageUploader
        self.userDataSaver = userDataSaver
    }
    
    private var navTitle: String {
        if mode == .createProfile {
            String(localized: "Create Profile")
        } else {
            String(localized: "Edit Profile")
        }
    }
    
    private var userId: UserId { currentUserIdProvider.currentUserId! }
    
    private func fetchExistingUserData() {
        Task {
            if let userData = try? await userDataFetcher.fetchUserData(withId: userId) {
                profileImageUrl = userData.profileImageUrl
                username = userData.username
            }
            
            initializationState = .initialized
        }
    }
    
    private func saveProfileData() async -> TaskStatus {
        do {
            guard let username = username else { return .failed("Username is invalid. A username...\n\(Username.rulesDescription)") }
            if mode == .createProfile {
                guard termsOfServiceAcceptance != nil else { return .failed("Please agree to the Terms of Service") }
                guard privacyPolicyAcceptance != nil else { return .failed("Please accept the Privacy Policy") }
            }

            var userData = UserData(
                id: userId,
                username: username,
                termsOfServiceAcceptance: termsOfServiceAcceptance,
                privacyPolicyAcceptance: privacyPolicyAcceptance
            )
            
            if profileImage != .init() {
                let url = try await imageUploader.upload(profileImage: profileImage, for: userData.id)
                userData.profileImageUrl = url
            }

            try await userDataSaver.saveOnboarding(userData: userData)
            sendToCurrentUserDataProvider(userData: userData)
            return .success
        } catch {
            let error = "Unable to save profile data: \(error.localizedDescription)"
            print(error)
            return .failed(error)
        }
    }
    
    private func sendToCurrentUserDataProvider(userData: UserData) {
        guard let provider = iocContainer.resolve(CurrentUserDataProvider.self) else { return }
        provider.onNew(userData: userData)
    }
    
    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }
    
    var body: some View {
        InitializedView()
            .overlay {
                if initializationState == .notInitialized {
                    BlockingSpinnerView()
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {}
            .onChange(of: initializationState, initial: true) { _, newState in
                withAnimation(.snappy) { showBlockingSpinner = newState == .notInitialized }
            }
            .onAppear { fetchExistingUserData() }
            .toolbar { Toolbar() }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(navTitle)
            .navigationBarBackButtonHidden()
            .foregroundStyle(Color.text)
            .background(Color.background)
    }
    
    @ViewBuilder func InitializedView() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                ProfileFormPictureField(
                    profileImage: $profileImage,
                    profileImageUrl: profileImageUrl
                )
                .padding(.bottom, 16)
                ProfileFormUsernameField(
                    username: $username,
                    userId: userId
                )
                if mode == .createProfile {
                    VStack(spacing: 0) {
                        TermsOfServiceField()
                        PrivacyPolicyField()
                    }
                    .padding(.horizontal, .padding)
                }
                Spacer()
                SaveButton()
                    .padding(.top, 16)
            }
            .padding(.horizontal, .padding)
            .padding(.vertical)
        }
        .background(Color.background)
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        if mode == .editProfile {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                }
                .accessibilityIdentifier("EditUserProfileView.Toolbar.DismissButton")
            }
        }
    }
    
    @ViewBuilder func TermsOfServiceField() -> some View {
        let message: AttributedString = {
            var text = AttributedString("I agree to the Terms of Service.")
            text.foregroundColor = Color.text
            guard let range = text.range(of: "Terms of Service") else { return text }
            text[range].foregroundColor = Color.accent

            return text
        }()
        
        HStack {
            Button {
                if termsOfServiceAcceptance == nil {
                    termsOfServiceAcceptance = .now
                } else {
                    termsOfServiceAcceptance = nil
                }
            } label: {
                let isAccepted = termsOfServiceAcceptance != nil
                Image(systemName: isAccepted ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isAccepted ? Color.accent : Color.text)
                    .padding(.vertical)
            }
            Button {
                showTermsOfService = true
            } label: {
                Text(message)
            }
            .sheet(isPresented: $showTermsOfService) {
                TextWall(TermsOfService.markdownContent)
            }
            Spacer()
        }
    }
    
    @ViewBuilder func PrivacyPolicyField() -> some View {
        let message: AttributedString = {
            var text = AttributedString("I accept the Privacy Policy.")
            text.foregroundColor = Color.text
            guard let range = text.range(of: "Privacy Policy") else { return text }
            text[range].foregroundColor = Color.accent

            return text
        }()
        
        HStack {
            Button {
                if privacyPolicyAcceptance == nil {
                    privacyPolicyAcceptance = .now
                } else {
                    privacyPolicyAcceptance = nil
                }
            } label: {
                let isAccepted = privacyPolicyAcceptance != nil
                Image(systemName: isAccepted ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isAccepted ? Color.accent : Color.text)
                    .padding(.vertical)
            }
            Button {
                showPrivacyPolicy = true
            } label: {
                Text(message)
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                TextWall(PrivacyPolicy.markdownContent)
            }
            Spacer()
        }
    }
    
    @ViewBuilder func TextWall(_ markdownContent: String) -> some View {
        ScrollView {
            Markdown(markdownContent)
                .markdownTextStyle { ForegroundColor(Color.text) }
                .frame(maxWidth: .infinity)
                .padding()
        }
        .background(Color.background)
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder func SaveButton() -> some View {
        TaskAwareButton {
            await saveProfileData()
        } label: {
            Text("Save")
                .foregroundStyle(Color.background)
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview("Edit") {
    NavigationStack {
        EditUserProfileView(
            mode: .editProfile,
            currentUserIdProvider: MockCurrentUserIdProvider(),
            userDataFetcher: MockUserDataFetcher(),
            imageUploader: MockProfileImageUploader(),
            userDataSaver: MockUserDataSaver()
        )
    }
}


#Preview("Create") {
    NavigationStack {
        EditUserProfileView(
            mode: .createProfile,
            currentUserIdProvider: MockCurrentUserIdProvider(),
            userDataFetcher: MockUserDataFetcher(),
            imageUploader: MockProfileImageUploader(),
            userDataSaver: MockUserDataSaver()
        )
    }
}
