//
//  EditTransactionCategoryView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import SwiftUI
import SwinjectAutoregistration

/// Adds or edits a transaction category, redesign palette: a title header with cancel/save, a symbol
/// profile badge, and surface field cards for the name, symbol, and optional spending goal. Self-
/// contained (own header + scroll) so it carries the redesign look without the shared Form chrome,
/// mirroring `EditRecurringExpenseView`.
struct EditTransactionCategoryView: View {
    
    private struct OptionalCategory: Equatable {
        let category: Transaction.Category?
        static let none: OptionalCategory = .init(category: nil)
    }
    
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?
    
    @State private var screenTitle: String = String(localized: "Add Category")
    @State private var symbolString: String? = nil
    @State private var nameString: String = ""
    @State private var nameInstructions: String = ""
    @State private var limitAmount: Money = .zero
    @State private var limitPeriod: TimeFrame.Period? = nil
    @State private var goalComparison: Transaction.Category.Goal.Comparison = .lessThan
    
    @State private var showAmountEntryView: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    @State private var showDeleteConfirmation: Bool = false
    @State private var showReassignSheet: Bool = false
    
    @State private var subscriptionLevel: SubscriptionLevel = .none
    private let subscriptionLevelProvider: SubscriptionLevelProvider
    
    private var categoryToEdit: OptionalCategory = .none
    
    @StateObject var budget: Budget
    
    init(
        budget: Budget
    ) {
        self.init(
            budget: budget,
            subscriptionLevelProvider: iocContainer~>SubscriptionLevelProvider.self
        )
    }
    
    init(
        budget: Budget,
        subscriptionLevelProvider: SubscriptionLevelProvider
    ) {
        self._budget = .init(wrappedValue: budget)
        self.subscriptionLevelProvider = subscriptionLevelProvider
    }
    
    public func editing(_ category: Transaction.Category) -> EditTransactionCategoryView {
        var view = self
        view.categoryToEdit = .init(category: category)
        return view
    }
    
    private var category: Transaction.Category? {
        guard let name = Transaction.Category.Name(nameString) else { return nil }
        guard let symbolString = symbolString else { return nil }
        guard let sfSymbol = Transaction.Category.SfSymbol(symbolString) else { return nil }
        
        let goal: Transaction.Category.Goal? = {
            guard let limitPeriod else { return nil }
            return .init(amount: limitAmount, period: limitPeriod, comparison: goalComparison)
        }()

        return .init(
            id: categoryToEdit.category?.id ?? Transaction.Category.Id(),
            name: name,
            sfSymbol: sfSymbol,
            goal: goal
        )
    }
    
    private var isFormComplete: Bool { category != nil }
    
    private func saveCategory() {
        guard let category = category else { return }
        budget.save(transactionCategory: category)
        dismiss()
    }

    private var affectedTransactions: [Transaction] {
        guard let category = categoryToEdit.category else { return [] }
        return budget.transactions.values.filter { $0.categoryId == category.id }
    }

    private func startDelete() {
        if affectedTransactions.isEmpty {
            showDeleteConfirmation = true
        } else {
            showReassignSheet = true
        }
    }

    private func deleteWithoutReassignment() {
        guard let category = categoryToEdit.category else { return }
        budget.remove(transactionCategory: category, replacingWith: nil)
        dismiss()
    }
    
    private func setNameInstructions(_ nameString: String) {
        withAnimation(.snappy) {
            if nameString.count < Transaction.Category.Name.minTextLength { nameInstructions = "Too short"; return }
            if nameString.count > Transaction.Category.Name.maxTextLength { nameInstructions = "Too long"; return }
            nameInstructions = "\(nameString.count)/\(Transaction.Category.Name.maxTextLength)"
        }
    }
    
    private func populateFields(_ category: OptionalCategory) {
        guard let category = category.category else { return }
        let isFormEmpty = symbolString == nil
        guard isFormEmpty else { return }
        
        screenTitle = String(localized: "Edit Category")
        symbolString = category.sfSymbol.value
        nameString = category.name.value
        limitPeriod = category.goal?.period
        limitAmount = category.goal?.amount ?? .zero
        goalComparison = category.goal?.comparison ?? .lessThan
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
                    SymbolField()
                    GoalCard()
                    if categoryToEdit.category != nil {
                        DeleteButton()
                    }
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
        .fullScreenCover(isPresented: $showAmountEntryView) {
            TransactionAmountEntryView(
                amount: $limitAmount,
                budget: budget
            )
        }
        .confirmationDialog(
            "Delete '\(categoryToEdit.category?.name.value ?? "")'?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteWithoutReassignment()
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showReassignSheet) {
            if let category = categoryToEdit.category {
                NavigationStack {
                    ReassignCategoryView(
                        budget: budget,
                        categoryToDelete: category,
                        affectedTransactionCount: affectedTransactions.count,
                        onCompleted: { dismiss() }
                    )
                }
            }
        }
        .onChange(of: nameString) { _, nameString in setNameInstructions(nameString) }
        .onChange(of: categoryToEdit, initial: true) { _, category in populateFields(category) }
        .onReceive(subscriptionLevelProvider.subscriptionLevelPublisher) { subscriptionLevel = $0 }
        .animation(.snappy, value: limitPeriod)
        .animation(.snappy, value: goalComparison)
        .animation(.snappy, value: symbolString)
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text(screenTitle)
                .font(.headline)
                .foregroundStyle(Color.appText)
                .padding(.horizontal, .barHeight)
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.appMutedText)
                Spacer(minLength: 0)
                Button("Save") { saveCategory() }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandTeal)
                    .opacity(isFormComplete ? 1 : .opacityButtonBackground)
                    .disabled(!isFormComplete)
                    .accessibilityIdentifier("EditTransactionCategoryView.Toolbar.SaveButton")
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Profile

    @ViewBuilder private func Profile() -> some View {
        IconCircle(systemName: symbolString ?? "tag.fill", size: 64, tint: .brandTeal)
            .frame(maxWidth: .infinity)
            .padding(.top, .paddingSmall)
    }

    // MARK: - Cards

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
                .card()
        }
    }

    @ViewBuilder private func NameField() -> some View {
        FieldCard("Name", footer: nameInstructions.isEmpty ? nil : LocalizedStringKey(nameInstructions)) {
            TextField(
                "Name",
                text: $nameString,
                prompt: Text("Groceries, Rent, Paycheck, etc...").foregroundStyle(Color.appMutedText)
            )
            .font(.title3)
            .foregroundStyle(Color.appText)
            .tint(Color.brandTeal)
            .autocapitalization(.words)
            .accessibilityIdentifier("EditTransactionCategoryView.NameField.TextField")
        }
    }

    @ViewBuilder private func SymbolField() -> some View {
        FieldCard("Symbol") {
            NavigationLink {
                SfSymbolPickerView(selectedSymbol: $symbolString)
            } label: {
                HStack(spacing: 8) {
                    Text(symbolString == nil ? "Choose a symbol" : "Change symbol")
                        .foregroundStyle(symbolString == nil ? Color.appMutedText : Color.appText)
                    Spacer(minLength: 0)
                    if let sfSymbol = symbolString {
                        Image(systemName: sfSymbol)
                            .foregroundStyle(Color.brandTeal)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.appMutedText)
                }
                .font(.body.weight(.semibold))
            }
            .accessibilityIdentifier("EditTransactionCategoryView.SymbolField.SelectSymbolButton")
        }
    }

    // MARK: - Goal

    @ViewBuilder private func GoalCard() -> some View {
        let footer: LocalizedStringKey = goalComparison == .lessThan
            ? "Track spending that should stay under this amount."
            : "Track a target you want to reach or exceed."

        FieldCard("Goal", footer: limitPeriod == nil ? "Add a goal to track this category against a target." : footer) {
            VStack(alignment: .leading, spacing: .padding) {
                PeriodRow()
                if limitPeriod != nil {
                    TargetRow()
                    AmountRow()
                }
            }
        }
    }

    @ViewBuilder private func PeriodRow() -> some View {
        SubField("Period") {
            Menu {
                LimitPeriodButton(period: nil)
                LimitPeriodButton(period: .week)
                LimitPeriodButton(period: .month)
                LimitPeriodButton(period: .year)
            } label: {
                MenuLabel(systemName: "calendar", text: limitPeriod?.rawValue ?? String(localized: "None"))
            }
        }
    }

    @ViewBuilder private func LimitPeriodButton(period: TimeFrame.Period?) -> some View {
        Button {
            limitPeriod = period
        } label: {
            HStack {
                Text(period?.rawValue ?? "None")
                if limitPeriod == period { Image(systemName: "checkmark") }
            }
        }
    }

    @ViewBuilder private func TargetRow() -> some View {
        SubField("Target") {
            PillSegmentedControl(
                selection: $goalComparison,
                options: Transaction.Category.Goal.Comparison.allCases,
                title: { $0.name }
            )
        }
    }

    @ViewBuilder private func AmountRow() -> some View {
        SubField("Amount") {
            Button {
                showAmountEntryView = true
            } label: {
                ValueLabel(text: limitAmount.formatted())
            }
            .accessibilityIdentifier("EditTransactionCategoryView.LimitAmountField.TextField")
        }
    }

    @ViewBuilder private func SubField<Content: View>(
        _ label: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appMutedText)
            content()
        }
    }

    @ViewBuilder private func MenuLabel(systemName: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemName)
                .foregroundStyle(Color.brandTeal)
            Text(text)
                .foregroundStyle(Color.appText)
                .contentTransition(.numericText())
            Spacer(minLength: 0)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .foregroundStyle(Color.appMutedText)
        }
        .font(.body.weight(.semibold))
    }

    @ViewBuilder private func ValueLabel(text: String) -> some View {
        HStack(spacing: 8) {
            Text(text)
                .foregroundStyle(Color.appText)
                .contentTransition(.numericText())
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.appMutedText)
        }
        .font(.body.weight(.semibold))
    }

    // MARK: - Delete

    @ViewBuilder private func DeleteButton() -> some View {
        Button(role: .destructive) {
            startDelete()
        } label: {
            HStack(spacing: .paddingSmall) {
                Image(systemName: "trash")
                Text("Delete Category")
            }
            .font(.headline)
            .foregroundStyle(Color.negative)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .paddingVerticalButtonMedium)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .foregroundStyle(Color.appSurface)
            }
        }
        .accessibilityIdentifier("EditTransactionCategoryView.DeleteButton")
        .padding(.top, .paddingSmall)
    }
}

#Preview("New") {
    NavigationStack {
        EditTransactionCategoryView(
            budget: Budget(info: .sample),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}

#Preview("Edit") {
    NavigationStack {
        EditTransactionCategoryView(
            budget: Budget(info: .sample),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
        .editing(.init(
            id: Transaction.Category.Id(),
            name: .init("Category To Edit")!,
            sfSymbol: .init("pencil.and.outline")!,
            goal: .init(amount: Money(100)!, period: .month)
        ))
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}
