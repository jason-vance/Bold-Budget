//
//  ContentView.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/27/24.
//

import SwiftUI
import SwinjectAutoregistration
import Combine

struct ContentView: View {
    
    @State var userAuthState: UserAuthState = .working
    @State var onboardingState: UserOnboardingState = .unknown

    private let userAuthStatePublisher: AnyPublisher<UserAuthState,Never>
    private let userOnboardingStatePublisher: AnyPublisher<UserOnboardingState,Never>

    init(
         userAuthStatePublisher: AnyPublisher<UserAuthState, Never>,
         userOnboardingStatePublisher: AnyPublisher<UserOnboardingState,Never>
    ) {
        self.userAuthStatePublisher = userAuthStatePublisher
        self.userOnboardingStatePublisher = userOnboardingStatePublisher
    }
    
    init() {
        let authStatePublisher = (iocContainer~>AuthenticationProvider.self)
            .userAuthStatePublisher
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
        
        let onboardingStatePublisher = (iocContainer~>UserOnboardingStateProvider.self)
            .userOnboardingStatePublisher
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
        
        self.init(
            userAuthStatePublisher: authStatePublisher,
            userOnboardingStatePublisher: onboardingStatePublisher
        )
    }
    
    var body: some View {
        AuthenticationStateRouter()
            .onReceive(userAuthStatePublisher) { userAuthState in
                withAnimation(.snappy) { self.userAuthState = userAuthState }
            }
            .onReceive(userOnboardingStatePublisher) { onboardingState in
                withAnimation(.snappy) { self.onboardingState = onboardingState }
            }
    }
    
    @ViewBuilder private func AuthenticationStateRouter() -> some View {
        if userAuthState == .loggedIn {
            OnboardingStateRouter()
                .transition(.asymmetric(insertion: .push(from: .trailing), removal: .push(from: .leading)))
        } else {
            AuthenticationView()
                .transition(.asymmetric(insertion: .offset(x: 0), removal: .offset(x: -100)))
        }
    }
    
    @ViewBuilder private func OnboardingStateRouter() -> some View {
        if onboardingState == .fullyOnboarded {
            OnboardedView()
        } else if onboardingState == .notOnboarded {
            NotOnboardedView()
        } else {
            BlockingSpinnerView()
                .overlay {  // To pre-load subscription info
                    SubscriptionMarketingView()
                        .opacity(0)
                }
        }
    }
    
    @ViewBuilder private func OnboardedView() -> some View {
        NavigationStack {
            BudgetsListView()
        }
    }
    
    @ViewBuilder private func NotOnboardedView() -> some View {
        NavigationStack {
            EditUserProfileView(mode: .createProfile)
        }
    }
}

#Preview("Signed Out") {
    let authStateSub = CurrentValueSubject<UserAuthState,Never>(.loggedOut)
    let onboardingStateSub = CurrentValueSubject<UserOnboardingState,Never>(.unknown)

    ContentView(
        userAuthStatePublisher: authStateSub.eraseToAnyPublisher(),
        userOnboardingStatePublisher: onboardingStateSub.eraseToAnyPublisher()
    )
}

#Preview("Not Onboarded") {
    let authStateSub = CurrentValueSubject<UserAuthState,Never>(.loggedIn)
    let onboardingStateSub = CurrentValueSubject<UserOnboardingState,Never>(.notOnboarded)

    ContentView(
        userAuthStatePublisher: authStateSub.eraseToAnyPublisher(),
        userOnboardingStatePublisher: onboardingStateSub.eraseToAnyPublisher()
    )
}

#Preview("Signed In") {
    let authStateSub = CurrentValueSubject<UserAuthState,Never>(.loggedIn)
    let onboardingStateSub = CurrentValueSubject<UserOnboardingState,Never>(.fullyOnboarded)

    ContentView(
        userAuthStatePublisher: authStateSub.eraseToAnyPublisher(),
        userOnboardingStatePublisher: onboardingStateSub.eraseToAnyPublisher()
    )
}
