//
//  BudgetSettingsView.swift
//  Bold Budget
//
//  Created by Jason Vance on 1/3/25.
//

import SwiftUI
import SwinjectAutoregistration

struct BudgetSettingsView: View {
    
    @StateObject var budget: Budget

    @State private var users: [UserData] = []
    
    private let userDataFetcher: UserDataFetcher
    
    init(budget: StateObject<Budget>) {
        self.init(
            budget: budget,
            userDataFetcher: iocContainer~>UserDataFetcher.self
        )
    }

    init(
        budget: StateObject<Budget>,
        userDataFetcher: UserDataFetcher
    ) {
        self._budget = budget
        self.userDataFetcher = userDataFetcher
    }
    
    private func fetchUsers() {
        Task {
            do {
                users = try await withThrowingTaskGroup(of: UserData.self) { group in
                    for userId in budget.info.users {
                        group.addTask {
                            return try await userDataFetcher.fetchUserData(withId: userId)
                        }
                    }
                    
                    var allUsers = [UserData]()
                    
                    for try await user in group {
                        allUsers.append(user)
                    }
                                        
                    return allUsers.sorted { $0.username?.value ?? "" > $1.username?.value ?? "" }
                }
            } catch {
                print("Failed to fetch users")
            }
        }
    }
    
    var body: some View {
        List {
            UsersSection()
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationTitle(budget.info.name.value)
        .foregroundStyle(Color.text)
        .background(Color.background)
        .onAppear { fetchUsers() }
    }
    
    @ViewBuilder private func UsersSection() -> some View {
        if !users.isEmpty {
            Section {
                ForEach(users) { user in
                    UserRow(user: user)
                }
            } header: {
                Text("Users")
            }
        }
    }
    
    @ViewBuilder private func UserRow(user: UserData) -> some View {
        HStack {
            ProfileImageView(
                user.profileImageUrl,
                size: 32,
                padding: .borderWidthThin
            )
            if let username = user.username {
                Text(username.value)
            }
            Spacer(minLength: 0)
        }
        .listRow()
    }
}

#Preview {
    NavigationStack {
        BudgetSettingsView(budget: .init(wrappedValue: Budget(info: .sample)))
    }
}
