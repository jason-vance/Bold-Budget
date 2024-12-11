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
    
    var currentUserDataPublisher: AnyPublisher<UserData?, Never> {
        userDataProvider.$userData.eraseToAnyPublisher()
    }
    
    let currentUserIdProvider = FirebaseAuthentication.instance
    let userDataProvider = FirebaseUserDataProvider()
    
    var currentUserIdSub: AnyCancellable? = nil

    static var instance: FirebaseCurrentUserDataProvider = .init()
    
    private init() {
        currentUserIdSub = currentUserIdProvider
            .currentUserIdPublisher
            .sink(receiveValue: onUpdate(userId:))
    }
    
    private func onUpdate(userId: UserId?) {
        if let userId = userId {
            userDataProvider.startListeningToUser(withId: userId)
        } else {
            userDataProvider.stopListeningToUser()
        }
    }
    
    func onNew(userData: UserData) {
        userDataProvider.userData = userData
    }
}
