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
    
    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?
    
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
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(spacing: .padding) {
                    Profile()
                    AdCard()
                    NameField()
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .alert(alertMessage, isPresented: $showAlert) {}
        .onChange(of: budgetToEdit, initial: true) { _, budget in populateFields(budget) }
        .onReceive(subscriptionManager.subscriptionLevelPublisher) { subscriptionLevel = $0 }
        .animation(.snappy, value: nameInstructions)
    }

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text(screenTitle)
                .font(.headline)
                .foregroundStyle(Color.appText)
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.appMutedText)
                    .accessibilityIdentifier("EditBudgetView.Toolbar.DismissButton")
                Spacer(minLength: 0)
                Button("Save") { saveBudget() }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandTeal)
                    .opacity(isFormComplete ? 1 : .opacityButtonBackground)
                    .disabled(!isFormComplete)
                    .accessibilityIdentifier("EditBudgetView.Toolbar.SaveButton")
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    @ViewBuilder private func Profile() -> some View {
        IconCircle(systemName: "chart.pie.fill", size: 64, tint: .brandTeal)
            .frame(maxWidth: .infinity)
            .padding(.top, .paddingSmall)
    }

    @ViewBuilder private func FieldCard<Content: View>(
        _ label: LocalizedStringKey,
        footer: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .kerning(0.5)
                .foregroundStyle(Color.appMutedText)
            content()
            if let footer {
                Text(footer)
                    .font(.caption2)
                    .foregroundStyle(Color.appMutedText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                .foregroundStyle(Color.appSurface)
        }
    }

    @ViewBuilder private func AdCard() -> some View {
        if subscriptionLevel == SubscriptionLevel.none {
            NativeAdListRow(ad: $ad, size: .small)
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                        .foregroundStyle(Color.appSurface)
                }
        }
    }

    @ViewBuilder private func NameField() -> some View {
        FieldCard("Name", footer: nameInstructions.isEmpty ? nil : LocalizedStringKey(nameInstructions)) {
            TextField(
                "Name",
                text: $nameString,
                prompt: Text("Family Budget, etc...").foregroundStyle(Color.appMutedText)
            )
            .font(.title3)
            .foregroundStyle(Color.appText)
            .tint(Color.brandTeal)
            .autocapitalization(.words)
            .accessibilityIdentifier("EditBudgetView.NameField.TextField")
        }
    }
}

#Preview("Add") {
    NavigationStack {
        EditBudgetView(
            currentUserIdProvider: MockCurrentUserIdProvider(),
            budgetCreator: MockBudgetSaver(throwing: false),
            subscriptionManager: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}

#Preview("Rename") {
    NavigationStack {
        EditBudgetView(
            currentUserIdProvider: MockCurrentUserIdProvider(),
            budgetCreator: MockBudgetSaver(throwing: false),
            subscriptionManager: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
        .editing(Budget(info: .sample))
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}
