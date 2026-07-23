//
//  AuthenticationView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/11/24.
//

import Combine
import SwiftUI
import _AuthenticationServices_SwiftUI
import SwinjectAutoregistration

struct AuthenticationView: View {

    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    @State var userAuthState: UserAuthState = .working
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    
    private let userAuthStatePublisher: AnyPublisher<UserAuthState,Never>
    private let signInWithResult: (Result<ASAuthorization, Error>) async throws -> ()
    
    init(
         userAuthStatePublisher: AnyPublisher<UserAuthState, Never>,
         signInWithResult: @escaping (Result<ASAuthorization, Error>) async throws -> ()
    ) {
        self.userAuthStatePublisher = userAuthStatePublisher
        self.signInWithResult = signInWithResult
    }
    
    init() {
        let authProvider = iocContainer~>AuthenticationProvider.self
        
        self.init(
            userAuthStatePublisher: authProvider.userAuthStatePublisher.eraseToAnyPublisher(),
            signInWithResult: { try await authProvider.signIn(withResult: $0) }
        )
    }
    
    private func show(errorMessage: String) {
        showError = true
        self.errorMessage = errorMessage
    }
    
    private func signIn(withResult result: Result<ASAuthorization, Error>) {
        Task {
            do {
                try await signInWithResult(result)
            } catch {
                show(errorMessage: "Unable to sign in: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            AppTitle()
            Spacer()
            SignInControls()
                .padding(.horizontal)
                .padding(.bottom, .padding)
        }
        .containerRelativeFrame(.horizontal)
        .background(Color.appBackground.ignoresSafeArea())
        .alert(errorMessage, isPresented: $showError) {}
        .onReceive(userAuthStatePublisher) { newAuthState in
            withAnimation(.snappy) {
                userAuthState = newAuthState
            }
        }
    }

    @ViewBuilder func SignInControls() -> some View {
        if userAuthState == .loggedOut {
            SignInButton()
        } else {
            ProgressSpinner()
        }
    }

    @ViewBuilder func AppTitle() -> some View {
        VStack(spacing: .padding) {
            Image("AuthBg")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
                .frame(width: 256, height: 256)
                .shadow(color: .black.opacity(0.15), radius: .cornerRadiusMedium, y: 6)
            VStack(spacing: .paddingSmall) {
                Text("Bold Budget")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.appText)
                Text("Take bold control of your money.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appMutedText)
            }
        }
    }

    @ViewBuilder func SignInButton() -> some View {
        SignInWithAppleButton(.continue) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            signIn(withResult: result)
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous))
    }

    @ViewBuilder func ProgressSpinner() -> some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(Color.brandTeal)
            .frame(height: 50)
    }
}

#Preview {
    let userStateSubject = CurrentValueSubject<UserAuthState,Never>(.loggedOut)
    
    AuthenticationView(
        userAuthStatePublisher: userStateSubject.eraseToAnyPublisher(),
        signInWithResult: { _ in
            userStateSubject.send(.working)
            try await Task.sleep(for: .seconds(1))
            userStateSubject.send(.loggedOut)
        }
    )
}
