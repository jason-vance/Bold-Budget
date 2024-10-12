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
        ZStack {
            AppTitle()
            SignInControls()
        }
        .containerRelativeFrame(.horizontal)
        .background(Color.background)
        .alert(errorMessage, isPresented: $showError) {}
        .onReceive(userAuthStatePublisher) { newAuthState in
            withAnimation(.snappy) {
                userAuthState = newAuthState
            }
        }
    }
    
    @ViewBuilder func SignInControls() -> some View {
        VStack{
            Spacer()
            if userAuthState == .loggedOut {
                SignInButton()
            } else {
                ProgressSpinner()
            }
        }
        .containerRelativeFrame(.horizontal)
    }
    
    @ViewBuilder func AppTitle() -> some View {
        VStack {
            Image("AuthBg")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
                .frame(width: 256, height: 256)
                .shadow(radius: .cornerRadiusMedium)
            Text("Bold Budget")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.text)
        }
    }
    
    @ViewBuilder func SignInButton() -> some View {
        SignInWithAppleButton(.continue) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            signIn(withResult: result)
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 48)
        .padding()
    }
    
    @ViewBuilder func ProgressSpinner() -> some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(Color.text)
            .frame(height: 48)
            .padding()
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
