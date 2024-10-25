//
//  UserProfileButton.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/24/24.
//

import SwiftUI
import SwinjectAutoregistration

struct UserProfileButton: View {
    
    @State private var currentUserData: UserData? = nil
    
    private let currentUserIdProvider: CurrentUserIdProvider
    private let currentUserDataProvider: CurrentUserDataProvider
    
    init() {
        self.init(
            currentUserIdProvider: iocContainer~>CurrentUserIdProvider.self,
            currentUserDataProvider: iocContainer~>CurrentUserDataProvider.self
        )
    }
    
    init(
        currentUserIdProvider: CurrentUserIdProvider,
        currentUserDataProvider: CurrentUserDataProvider
    ) {
        self.currentUserIdProvider = currentUserIdProvider
        self.currentUserDataProvider = currentUserDataProvider
    }
    
    private var currentUserId: UserId? { currentUserIdProvider.currentUserId }
    
    var body: some View {
        NavigationLink {
            if let userId = currentUserId {
                UserProfileView(userId: userId)
            }
        } label: {
            ProfileImageView(
                currentUserData?.profileImageUrl,
                size: 22,
                padding: .borderWidthThin
            )
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileButton(
            currentUserIdProvider: MockCurrentUserIdProvider(),
            currentUserDataProvider: MockCurrentUserDataProvider()
        )
    }
}
