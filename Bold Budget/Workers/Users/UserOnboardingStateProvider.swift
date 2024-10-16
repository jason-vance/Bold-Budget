//
//  UserOnboardingStateProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import Foundation
import Combine

class UserOnboardingStateProvider {
    
    @Published var userOnboardingState: UserOnboardingState = .unknown
    var userOnboardingStatePublisher: Published<UserOnboardingState>.Publisher { $userOnboardingState }
    
    private var currentUserId: UserId? = nil

    private let userIdProvider: CurrentUserIdProvider
    private let userDataProvider: UserDataProvider
    
    private var userIdSub: AnyCancellable? = nil
    private var userDataSub: AnyCancellable? = nil

    init(userIdProvider: CurrentUserIdProvider, userDataProvider: UserDataProvider) {
        self.userIdProvider = userIdProvider
        self.userDataProvider = userDataProvider

        listenToUserDataChanges()
    }
    
    private func listenToUserDataChanges() {
        userIdSub = userIdProvider.currentUserIdPublisher
            .sink(receiveValue: onUpdate(currentUserId:))
        userDataSub = userDataProvider.userDataPublisher
            .sink(receiveValue: onUpdate(userData:))
    }
    
    private func onUpdate(currentUserId: UserId?) {
        guard self.currentUserId != currentUserId else { return }
        
        self.currentUserId = currentUserId
        self.userOnboardingState = .unknown
        
        if let userId = currentUserId {
            userDataProvider.startListeningToUser(withId: userId)
        }
    }
    
    private func onUpdate(userData: UserData) {
        if userData.isFullyOnboarded {
            self.userOnboardingState = .fullyOnboarded
        } else {
            self.userOnboardingState = .notOnboarded
        }
    }
}
