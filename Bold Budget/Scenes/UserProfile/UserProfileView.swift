//
//  UserProfileView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/11/24.
//

import SwiftUI
import SwinjectAutoregistration

struct UserProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    public let userId: UserId
    private let currentUserIdProvider: CurrentUserIdProvider
        
    @State private var userIdState: UserId?
    
    private var currentUserId: UserId? { currentUserIdProvider.currentUserId }
    
    init(
        userId: UserId
    ) {
        self.init(
            userId: userId,
            currentUserIdProvider: iocContainer~>CurrentUserIdProvider.self
        )
    }
    
    init(
        userId: UserId,
        currentUserIdProvider: CurrentUserIdProvider
    ) {
        self.userId = userId
        self.currentUserIdProvider = currentUserIdProvider
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Text("HEllo")
                        .listRowNoChrome()
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
            }
            .toolbar { Toolbar() }
            .foregroundStyle(Color.text)
            .background(Color.background)
        }
        .onChange(of: userId, initial: true) { _, userId in userIdState = userId }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                TitleBarButtonLabel(sfSymbol: "xmark")
            }
        }
        ToolbarItemGroup(placement: .principal) {
            Text(currentUserId?.value ?? "User")
                .font(.body.bold())
        }
    }
}

#Preview {
    UserProfileView(userId: .sample)
}
