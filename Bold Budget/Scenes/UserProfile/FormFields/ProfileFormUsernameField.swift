//
//  ProfileFormUsernameField.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/15/24.
//

import SwiftUI
import SwinjectAutoregistration

struct ProfileFormUsernameField: View {
    
    @Binding var username: Username?
    private let userId: UserId

    @State private var usernameStr: String = ""
    @State private var isAvailable: Bool = false
    @State private var isCheckingAvailability: Bool = false
    
    private let usernameAvailabilityChecker: UsernameAvailabilityChecker
    
    init(
        username: Binding<Username?>,
        userId: UserId
    ) {
        self.init(
            username: username,
            userId: userId,
            usernameAvailabilityChecker: iocContainer~>UsernameAvailabilityChecker.self
        )
    }
    
    init(
        username: Binding<Username?>,
        userId: UserId,
        usernameAvailabilityChecker: UsernameAvailabilityChecker
    ) {
        self._username = username
        self.userId = userId
        self.usernameAvailabilityChecker = usernameAvailabilityChecker
    }
    
    private var isUsernameValidAndAvailable: Bool { username != nil && isAvailable }
    
    private func checkAvailability() {
        guard let username = username else { return }
        isAvailable = false
        isCheckingAvailability = true
        
        Task {
            do {
                guard let checker = iocContainer.resolve(UsernameAvailabilityChecker.self) else {
                    return
                }
                
                isAvailable = try await checker.isAvailable(username: username, forUser: userId)
            } catch {
                print("Failed to check username availability. \(error.localizedDescription)")
            }
            isCheckingAvailability = false
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Username")
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .kerning(0.5)
                .foregroundStyle(Color.appMutedText)
            TextField(
                "Username",
                text: $usernameStr,
                prompt: Text("Username").foregroundStyle(Color.appMutedText)
            )
            .font(.title3)
            .foregroundStyle(Color.appText)
            .tint(Color.brandTeal)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .accessibilityIdentifier("ProfileFormUsernameField.TextField")
            UsernameErrorView()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .onChange(of: usernameStr) { _, newValue in
            guard username?.value != newValue else { return }
            username = Username(newValue)

            checkAvailability()
        }
        .onChange(of: username, initial: true) { _, newValue in
            guard let value = newValue else { return }
            guard usernameStr != value.value else { return }
            usernameStr = value.value

            checkAvailability()
        }
    }

    @ViewBuilder func UsernameErrorView() -> some View {
        let icon: String
        let text: String
        let color: Color
        if isUsernameValidAndAvailable {
            icon = "checkmark.circle.fill"
            text = String(localized: "Username is valid and available")
            color = .brandTeal
        } else if isCheckingAvailability {
            icon = "questionmark.circle.fill"
            text = String(localized: "Checking...")
            color = .appMutedText
        } else {
            icon = "exclamationmark.octagon.fill"
            text = String(localized: "3-32 characters. No spaces. At least 1 letter.")
            color = .appMutedText
        }

        return HStack(spacing: .paddingSmall) {
            Image(systemName: icon)
            Text(text)
            Spacer(minLength: 0)
        }
        .font(.caption)
        .foregroundStyle(color)
    }
}

#Preview("Pre-filled Username") {
    StatefulPreviewContainer(Username("json")) { username in
        VStack {
            ProfileFormUsernameField(
                username: username,
                userId: .sample,
                usernameAvailabilityChecker: MockUsernameAvailabilityChecker()
            )
            Text(username.wrappedValue?.value ?? "<Empty>")
        }
    }
}

#Preview("Nil Username") {
    StatefulPreviewContainer(nil) { username in
        VStack {
            ProfileFormUsernameField(
                username: username,
                userId: .sample,
                usernameAvailabilityChecker: MockUsernameAvailabilityChecker()
            )
            Text(username.wrappedValue?.value ?? "<Empty>")
        }
    }
}
