//
//  AddBudgetView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/22/24.
//

import SwiftUI
import SwinjectAutoregistration

struct AddBudgetView: View {
    
    @Environment(\.dismiss) private var dismiss: DismissAction
    
    @State private var nameString: String = ""
    @State private var nameInstructions: String = ""
    //TODO: set the instructions for the budget name
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    private let currentUserIdProvider: CurrentUserIdProvider
    private let budgetCreator: BudgetCreator
    private let subscriptionManager: SubscriptionLevelProvider
    
    init() {
        self.init(
            currentUserIdProvider: iocContainer~>CurrentUserIdProvider.self,
            budgetCreator: iocContainer~>BudgetCreator.self,
            subscriptionManager: iocContainer~>SubscriptionLevelProvider.self
        )
    }
    
    init(
        currentUserIdProvider: CurrentUserIdProvider,
        budgetCreator: BudgetCreator,
        subscriptionManager: SubscriptionLevelProvider
    ) {
        self.currentUserIdProvider = currentUserIdProvider
        self.budgetCreator = budgetCreator
        self.subscriptionManager = subscriptionManager
    }
    
    private var currentUserId: UserId? { currentUserIdProvider.currentUserId }
    
    private var isFormComplete: Bool { budget != nil }
    
    private var budget: BudgetInfo? {
        guard let userId = currentUserId else { return nil }
        guard let name = BudgetInfo.Name(nameString) else { return nil }

        return BudgetInfo(
            id: UUID().uuidString,
            name: name,
            users: [userId]
        )
    }
    
    private func saveBudget() {
        Task {
            do {
                guard let budget = budget else { throw TextError("Invalid Budget") }
                guard let userId = currentUserId else { throw TextError("Invalid User Id") }
                
                try await budgetCreator.create(budget: budget, ownedBy: userId)
                dismiss()
            } catch {
                let errorMsg = "Error saving budget. \(error.localizedDescription)"
                print(errorMsg)
                show(alert: errorMsg)
            }
        }
    }
    
    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }
    
    var body: some View {
        //TODO: I should probably take off this NavigationStack?
        NavigationStack {
            Form {
                AdSection()
                Section {
                    NameField()
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom) { //this will push the view farther when the keyboard is shown
                Color.clear.frame(height: 100)
            }
            .toolbar { Toolbar() }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Add a Budget")
            .navigationBarBackButtonHidden()
            .foregroundStyle(Color.text)
            .background(Color.background)
            .alert(alertMessage, isPresented: $showAlert) {}
        }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            CloseButton()
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            SaveButton()
        }
    }
    
    @ViewBuilder func CloseButton() -> some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityIdentifier("AddBudgetView.Toolbar.DismissButton")
    }
    
    @ViewBuilder func SaveButton() -> some View {
        Button {
            saveBudget()
        } label: {
            Image(systemName: "checkmark")
        }
        .opacity(isFormComplete ? 1 : .opacityButtonBackground)
        .disabled(!isFormComplete)
        .accessibilityIdentifier("AddBudgetView.Toolbar.SaveButton")
    }
    
    @ViewBuilder func AdSection() -> some View {
        if subscriptionManager.subscriptionLevel == .none {
            Section {
                SimpleBannerAdView()
            }
        }
    }
    
    @ViewBuilder func NameField() -> some View {
        VStack {
            HStack {
                Text("Name")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                Text(nameInstructions)
                    .font(.caption2)
                    .foregroundStyle(Color.text.opacity(0.75))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
            }
            TextField("Name",
                      text: $nameString,
                      prompt: Text("Family Budget, etc...").foregroundStyle(Color.text.opacity(0.7))
            )
            .textFieldSmall()
            .autocapitalization(.words)
            .accessibilityIdentifier("AddBudgetView.NameField.TextField")
        }
        .formRow()
    }
}

#Preview {
    AddBudgetView()
}
