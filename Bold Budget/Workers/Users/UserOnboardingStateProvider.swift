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
    
    private let userDataProvider: CurrentUserDataProvider
    
    private var userIdSub: AnyCancellable? = nil
    private var userDataSub: AnyCancellable? = nil

    init(userDataProvider: CurrentUserDataProvider) {
        self.userDataProvider = userDataProvider

        listenToUserDataChanges()
    }
    
    private func listenToUserDataChanges() {
        userDataSub = userDataProvider.currentUserDataPublisher
            .sink(receiveValue: onUpdate(userData:))
    }
    
    private func onUpdate(userData: UserData?) {
        guard let userData = userData else {
            userOnboardingState = .unknown
            return
        }
        
        if userData.isFullyOnboarded {
            userOnboardingState = .fullyOnboarded
        } else {
            userOnboardingState = .notOnboarded
        }
    }
}
