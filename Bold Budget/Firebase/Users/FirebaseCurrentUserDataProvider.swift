//
//  FirebaseCurrentUserDataProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/17/24.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseCurrentUserDataProvider: CurrentUserDataProvider {
    
    @Published var currentUserData: UserData?
    var currentUserDataPublisher: AnyPublisher<UserData?, Never> { $currentUserData.eraseToAnyPublisher() }
    
    var userDocListener: ListenerRegistration?
    
    let currentUserIdProvider = FirebaseAuthentication.instance
    let userRepo = FirebaseUserRepository()
    
    var currentUserIdSub: AnyCancellable? = nil
    
    static var instance: FirebaseCurrentUserDataProvider = .init()
    
    private init() {
        currentUserIdSub = currentUserIdProvider
            .currentUserIdPublisher
            .sink(receiveValue: onUpdate(userId:))
    }
    
    deinit {
        cleanUpListeners()
    }
    
    private func cleanUpListeners() {
        userDocListener?.remove()
        userDocListener = nil
    }
    
    private func onUpdate(userId: UserId?) {
        guard let userId = userId else { return }
        startListeningToUser(withId: userId)
    }
    
    private func startListeningToUser(withId id: UserId) {
        cleanUpListeners()
        
        userDocListener = userRepo.listenToUserDocument(
            withId: id,
            onUpdate: onUpdate(userDoc:)
        )
    }
    
    private func onUpdate(userDoc: FirebaseUserDoc?) {
        guard let userData = userDoc?.toUserData() else {
            currentUserData = nil
            return
        }
        currentUserData = userData
    }
}
