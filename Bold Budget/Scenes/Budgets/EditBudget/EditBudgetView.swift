//
//  EditBudgetView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/22/24.
//

import SwiftUI
import SwinjectAutoregistration

struct EditBudgetView: View {
    
    private struct OptionalBudget: Equatable {
        let budget: Budget?
        static let none: OptionalBudget = .init(budget: nil)
    }
    
    @Environment(\.dismiss) private var dismiss: DismissAction
    
    private var budgetToEdit: OptionalBudget = .none
    
    @State private var screenTitle: String = String(localized: "Add a Budget")
    @State private var nameString: String = ""
    
    @State private var subscriptionLevel: SubscriptionLevel? = nil
    
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
    
    public func editing(_ budget: Budget) -> EditBudgetView {
        var view = self
        view.budgetToEdit = .init(budget: budget)
        return view
    }
    
    private var currentUserId: UserId? { currentUserIdProvider.currentUserId }
    
    private var isFormComplete: Bool { budgetInfo != nil }
    
    private var budgetInfo: BudgetInfo? {
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
                guard let budgetInfo = budgetInfo else { throw TextError("Invalid Budget") }
                guard let userId = currentUserId else { throw TextError("Invalid User Id") }
                
                if let budget = budgetToEdit.budget {
                    budget.set(name: budgetInfo.name)
                } else {
                    try await budgetCreator.create(budget: budgetInfo, ownedBy: userId)
                }
                dismiss()
            } catch {
                let errorMsg = "Error saving budget. \(error.localizedDescription)"
                print(errorMsg)
                show(alert: errorMsg)
            }
        }
    }
    
    private var nameInstructions: String {
        if nameString.isEmpty { return "" }
        if nameString.count < BudgetInfo.Name.minTextLength { return "Too short" }
        if nameString.count > BudgetInfo.Name.maxTextLength { return "Too long" }
        return "\(nameString.count)/\(BudgetInfo.Name.maxTextLength)"
    }
    
    private func populateFields(_ budget: OptionalBudget) {
        guard let budget = budget.budget else { return }
        let isFormEmpty = nameString.isEmpty
        guard isFormEmpty else { return }
        
        screenTitle = String(localized: "Rename Budget")
        nameString = budget.info.name.value
    }
    
    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }
    
    var body: some View {
        Form {
            AdSection()
            Section {
                NameField()
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .toolbar { Toolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(screenTitle)
        .navigationBarBackButtonHidden()
        .foregroundStyle(Color.text)
        .background(Color.background)
        .alert(alertMessage, isPresented: $showAlert) {}
        .onChange(of: budgetToEdit, initial: true) { _, budget in populateFields(budget) }
        .onReceive(subscriptionManager.subscriptionLevelPublisher) { subscriptionLevel = $0 }
        .animation(.snappy, value: nameInstructions)
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
        .accessibilityIdentifier("EditBudgetView.Toolbar.DismissButton")
    }
    
    @ViewBuilder func SaveButton() -> some View {
        Button {
            saveBudget()
        } label: {
            Image(systemName: "checkmark")
        }
        .opacity(isFormComplete ? 1 : .opacityButtonBackground)
        .disabled(!isFormComplete)
        .accessibilityIdentifier("EditBudgetView.Toolbar.SaveButton")
    }
    
    @ViewBuilder func AdSection() -> some View {
        if subscriptionLevel == SubscriptionLevel.none {
            Section {
                SimpleNativeAdView(size: .small)
                    .listRow()
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
                    .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
            }
            TextField("Name",
                      text: $nameString,
                      prompt: Text("Family Budget, etc...").foregroundStyle(Color.text.opacity(.opacityTextFieldPrompt))
            )
            .textFieldSmall()
            .autocapitalization(.words)
            .accessibilityIdentifier("EditBudgetView.NameField.TextField")
        }
        .formRow()
    }
}

#Preview {
    EditBudgetView()
}
