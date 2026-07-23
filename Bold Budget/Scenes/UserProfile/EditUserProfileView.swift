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
            .onAppear { fetchExistingUserData() }
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden()
            .foregroundStyle(Color.appText)
            .background(Color.appBackground.ignoresSafeArea())
    }

    @ViewBuilder func InitializedView() -> some View {
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(spacing: .padding) {
                    ProfileFormPictureField(
                        profileImage: $profileImage,
                        profileImageUrl: profileImageUrl,
                        profileImageSize: 140
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, .paddingSmall)
                    ProfileFormUsernameField(
                        username: $username,
                        userId: userId
                    )
                    if mode == .createProfile {
                        AgreementsCard()
                    }
                    SaveButton()
                        .padding(.top, .paddingSmall)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text(navTitle)
                .font(.headline)
                .foregroundStyle(Color.appText)
            if mode == .editProfile {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.appMutedText)
                    }
                    .accessibilityIdentifier("EditUserProfileView.Toolbar.DismissButton")
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Agreements

    @ViewBuilder private func AgreementsCard() -> some View {
        VStack(spacing: 0) {
            TermsOfServiceField()
            RowDivider()
            PrivacyPolicyField()
        }
        .card(0)
    }

    @ViewBuilder private func RowDivider(opacity: Double = 0.15) -> some View {
        Rectangle()
            .fill(Color.appMutedText.opacity(opacity))
            .frame(height: 1)
            .padding(.leading, .padding)
    }

    @ViewBuilder func TermsOfServiceField() -> some View {
        let message: AttributedString = {
            var text = AttributedString(String(localized: "I agree to the Terms of Service."))
            text.foregroundColor = Color.appText
            guard let range = text.range(of: "Terms of Service") else { return text }
            text[range].foregroundColor = Color.brandTeal

            return text
        }()

        HStack(spacing: .padding) {
            Button {
                termsOfServiceAcceptance = termsOfServiceAcceptance == nil ? .now : nil
            } label: {
                let isAccepted = termsOfServiceAcceptance != nil
                Image(systemName: isAccepted ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isAccepted ? Color.brandTeal : Color.appMutedText)
            }
            Button {
                showTermsOfService = true
            } label: {
                Text(message)
            }
            .sheet(isPresented: $showTermsOfService) {
                TextWall(TermsOfService.markdownContent)
            }
            Spacer(minLength: 0)
        }
        .padding(.padding)
    }

    @ViewBuilder func PrivacyPolicyField() -> some View {
        let message: AttributedString = {
            var text = AttributedString(String(localized: "I accept the Privacy Policy."))
            text.foregroundColor = Color.appText
            guard let range = text.range(of: "Privacy Policy") else { return text }
            text[range].foregroundColor = Color.brandTeal

            return text
        }()

        HStack(spacing: .padding) {
            Button {
                privacyPolicyAcceptance = privacyPolicyAcceptance == nil ? .now : nil
            } label: {
                let isAccepted = privacyPolicyAcceptance != nil
                Image(systemName: isAccepted ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isAccepted ? Color.brandTeal : Color.appMutedText)
            }
            Button {
                showPrivacyPolicy = true
            } label: {
                Text(message)
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                TextWall(PrivacyPolicy.markdownContent)
            }
            Spacer(minLength: 0)
        }
        .padding(.padding)
    }

    @ViewBuilder func TextWall(_ markdownContent: String) -> some View {
        ScrollView {
            Markdown(markdownContent)
                .markdownTextStyle { ForegroundColor(Color.appText) }
                .frame(maxWidth: .infinity)
                .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .presentationDragIndicator(.visible)
    }

    // MARK: - Save

    @ViewBuilder func SaveButton() -> some View {
        TaskAwareButton(
            buttonColor: .brandTeal,
            contentColor: .appBackground
        ) {
            await saveProfileData()
        } label: {
            Text("Save")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("EditUserProfileView.SaveButton")
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
