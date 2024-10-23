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
    
    private let currentUserIdProvider: CurrentUserIdProvider
    
    init() {
        self.init(
            currentUserIdProvider: iocContainer~>CurrentUserIdProvider.self
        )
    }
    
    init(
        currentUserIdProvider: CurrentUserIdProvider
    ) {
        self.currentUserIdProvider = currentUserIdProvider
    }
    
    private var currentUserId: UserId? { currentUserIdProvider.currentUserId }
    
    private var isFormComplete: Bool { budget != nil }
    
    private var budget: Budget? {
        guard let userId = currentUserId else { return nil }
        guard let name = Budget.Name(nameString) else { return nil }

        return Budget(
            id: UUID().uuidString,
            name: name,
            owner: userId
        )
    }
    
    private func saveBudget() {
        //TODO: Implement saveBudget
    }
    
    var body: some View {
        NavigationStack {
            Form {
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
        //TODO: Hide this if budgets is empty
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
