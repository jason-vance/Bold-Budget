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
    
    private let userAuthStatePublisher: AnyPublisher<UserAuthState,Never>
    
    init(
         userAuthStatePublisher: AnyPublisher<UserAuthState, Never>
    ) {
        self.userAuthStatePublisher = userAuthStatePublisher
    }
    
    init() {
        let authProvider = iocContainer~>AuthenticationProvider.self
        let publisher = authProvider
            .userAuthStatePublisher
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
        
        self.init(userAuthStatePublisher: publisher)
    }
    
    var body: some View {
        AuthenticationStateRouter()
            .onReceive(userAuthStatePublisher) { userAuthState in
                withAnimation(.snappy) { self.userAuthState = userAuthState }
            }
    }
    
    @ViewBuilder private func AuthenticationStateRouter() -> some View {
        if userAuthState == .loggedIn {
            SignedInView()
                .transition(.asymmetric(insertion: .push(from: .trailing), removal: .push(from: .leading)))
        } else {
            AuthenticationView()
                .transition(.asymmetric(insertion: .offset(x: 0), removal: .offset(x: -100)))
        }
    }
    
    @ViewBuilder private func SignedInView() -> some View {
        NavigationStack {
            DashboardView()
        }
    }
}

#Preview {
    ContentView()
}
