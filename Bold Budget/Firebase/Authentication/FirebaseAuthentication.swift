//
//  FirebaseAuthentication.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/11/24.
//

import Combine
import Foundation
import FirebaseAuth
import AuthenticationServices
import FirebaseAnalytics

class FirebaseAuthentication {
    
    @Published var currentUser: User?
    var currentUserId: UserId? { .init(currentUser?.uid) }
    var currentUserIdPublisher: AnyPublisher<UserId?,Never> {
        $currentUser
            .map { .init($0?.uid ?? "") }
            .eraseToAnyPublisher()
    }
    
    @Published var userAuthState: UserAuthState = .working
    var userAuthStatePublisher: Published<UserAuthState>.Publisher { $userAuthState }
    
    var authStateChangeListenerHandle: AuthStateDidChangeListenerHandle?
    
    static let instance: FirebaseAuthentication = .init()
    
    private init() {
        listenForAuthStateChanges()
    }
    
    deinit {
        stopListeningForAuthStateChanges()
    }
    
    private func listenForAuthStateChanges() {
        authStateChangeListenerHandle = Auth.auth().addStateDidChangeListener { auth, user in
            DispatchQueue.main.async { [weak self] in
                if let user = user {
                    self?.currentUser = user
                    self?.userAuthState = .loggedIn
                    FirebaseAnalytics.Analytics.setUserID(user.uid)
                } else {
                    self?.currentUser = nil
                    self?.userAuthState = .loggedOut
                    FirebaseAnalytics.Analytics.setUserID(nil)
                }
            }
        }
    }
    
    private func stopListeningForAuthStateChanges() {
        if let handle = authStateChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signIn(withResult result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .success(let authorization):
            try await signIn(withAuthorization: authorization)
        case .failure(let error):
            throw error
        }
    }
    
    func signIn(withAuthorization authorization: ASAuthorization) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw TextError("Unable to fetch credential")
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
            throw TextError("Unable to fetch identity token")
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw TextError("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
        }
        
        DispatchQueue.main.sync {
            self.userAuthState = .working
        }
        
        // Initialize a Firebase credential, including the user's full name.
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nil,
            fullName: appleIDCredential.fullName)
        
        try await Auth.auth().signIn(with: credential)
    }
    
    private func reathenticate(withAuthorization authorization: ASAuthorization) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw TextError("Unable to fetch credential")
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
            throw TextError("Unable to fetch identity token")
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw TextError("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
        }
        guard let currentUser = currentUser else {
            throw TextError("User is not logged in")
        }
        
        // Initialize a Firebase credential, including the user's full name.
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nil,
            fullName: appleIDCredential.fullName)
        
        try await currentUser.reauthenticate(with: credential)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func deleteUser(authorization: ASAuthorization) async throws {
        guard let currentUser = currentUser else {
            throw TextError("User is not logged in")
        }
        
        try await reathenticate(withAuthorization: authorization)
        try await currentUser.delete()
    }
}

extension FirebaseAuthentication: AuthenticationProvider { }

extension FirebaseAuthentication: CurrentUserIdProvider { }

extension FirebaseAuthentication: UserSignOutService { }

extension FirebaseAuthentication: UserAccountDeleter { }
