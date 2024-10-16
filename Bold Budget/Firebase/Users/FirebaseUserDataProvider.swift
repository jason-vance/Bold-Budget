//
//  FirebaseUserDataProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseUserDataProvider: UserDataProvider {
    
    @Published var userData: UserData? = nil
    var userDataPublisher: AnyPublisher<UserData,Never> {
        $userData
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    var userDocListener: ListenerRegistration?
    
    let userRepo = FirebaseUserRepository()
    
    deinit {
        cleanUpListeners()
    }
    
    private func cleanUpListeners() {
        userDocListener?.remove()
        userDocListener = nil
    }
    
    func startListeningToUser(withId id: UserId) {
        cleanUpListeners()
        
        userDocListener = userRepo.listenToUserDocument(withId: id) { userDoc in
            if let userData = userDoc?.toUserData() {
                self.userData = userData
            } else {
                self.userData = UserData(id: id)
            }
        }
    }
}
