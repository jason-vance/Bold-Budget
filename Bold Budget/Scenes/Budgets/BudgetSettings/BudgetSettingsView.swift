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
    @State private var budgetUsers: [UserId:Budget.User] = [:]
    
    private let userDataFetcher: UserDataFetcher
    private let budgetUserFetcher: BudgetUserFetcher

    init(budget: StateObject<Budget>) {
        self.init(
            budget: budget,
            userDataFetcher: iocContainer~>UserDataFetcher.self,
            budgetUserFetcher: iocContainer~>BudgetUserFetcher.self
        )
    }

    init(
        budget: StateObject<Budget>,
        userDataFetcher: UserDataFetcher,
        budgetUserFetcher: BudgetUserFetcher
    ) {
        self._budget = budget
        self.userDataFetcher = userDataFetcher
        self.budgetUserFetcher = budgetUserFetcher
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
                print("Failed to fetch users. \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchUserRoles() {
        Task {
            do {
                let users = try await budgetUserFetcher.fetchUsers(in: budget.info)
                budgetUsers = .init(uniqueKeysWithValues: users.map { ($0.id, $0) })
            } catch {
                print("Failed to fetch users' roles. \(error.localizedDescription)")
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
        .onAppear { fetchUserRoles() }
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
            if let role = budgetUsers[user.id]?.role {
                Text("(\(role))")
            }
        }
        .listRow()
    }
}

#Preview {
    NavigationStack {
        BudgetSettingsView(
            budget: .init(wrappedValue: Budget(info: .sample)),
            userDataFetcher: MockUserDataFetcher(),
            budgetUserFetcher: MockBudgetUserFetcher()
        )
    }
}
