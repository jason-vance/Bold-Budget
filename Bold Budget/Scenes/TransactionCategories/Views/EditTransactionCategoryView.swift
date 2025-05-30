//
//  EditTransactionCategoryView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import SwiftUI
import SwinjectAutoregistration

struct EditTransactionCategoryView: View {
    
    private struct OptionalCategory: Equatable {
        let category: Transaction.Category?
        static let none: OptionalCategory = .init(category: nil)
    }
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var screenTitle: String = String(localized: "Add Category")
    @State private var kind: Transaction.Category.Kind = .expense
    @State private var symbolString: String? = nil
    @State private var nameString: String = ""
    @State private var nameInstructions: String = ""
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
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

        return .init(
            id: categoryToEdit.category?.id ?? Transaction.Category.Id(),
            kind: kind,
            name: name,
            sfSymbol: sfSymbol
        )
    }
    
    private var isFormComplete: Bool { category != nil }
    
    private func saveCategory() {
        guard let category = category else { return }
        budget.save(transactionCategory: category)
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
        kind = category.kind
        symbolString = category.sfSymbol.value
        nameString = category.name.value
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
                KindField()
                SymbolField()
            } header: {
                Text("")
                    .foregroundStyle(Color.text)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .toolbar { Toolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(screenTitle)
        .foregroundStyle(Color.text)
        .background(Color.background)
        .alert(alertMessage, isPresented: $showAlert) {}
        .onChange(of: nameString) { _, nameString in setNameInstructions(nameString) }
        .onChange(of: categoryToEdit, initial: true) { _, category in populateFields(category) }
        .onReceive(subscriptionLevelProvider.subscriptionLevelPublisher) { subscriptionLevel = $0 }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            SaveButton()
        }
    }
    
    @ViewBuilder func SaveButton() -> some View {
        Button {
            saveCategory()
        } label: {
            Image(systemName: "checkmark")
        }
        .opacity(isFormComplete ? 1 : .opacityButtonBackground)
        .disabled(!isFormComplete)
        .accessibilityIdentifier("EditTransactionCategoryView.Toolbar.SaveButton")
    }
    
    @ViewBuilder func AdSection() -> some View {
        if subscriptionLevel == SubscriptionLevel.none {
            Section {
                SimpleNativeAdView(size: .small)
                    .listRow()
            }
        }
    }
    
    @ViewBuilder func KindField() -> some View {
        HStack {
            Text("Income or Expense")
                .foregroundStyle(Color.text)
            Spacer(minLength: 0)
            Menu {
                Button {
                    kind = .expense
                } label: {
                    HStack {
                        Text(Transaction.Category.Kind.expense.name)
                        if kind == .expense { Image(systemName: "checkmark") }
                    }
                }
                Button {
                    kind = .income
                } label: {
                    HStack {
                        Text(Transaction.Category.Kind.income.name)
                        if kind == .income { Image(systemName: "checkmark") }
                    }
                }
            } label: {
                Text(kind.name)
                    .buttonLabelSmall()
            }
        }
        .formRow()
    }
    
    @ViewBuilder func NameField() -> some View {
        VStack {
            HStack {
                Text("Name")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
            }
            TextField("Name",
                      text: $nameString,
                      prompt: Text("Groceries, Rent, Paycheck, etc...").foregroundStyle(Color.text.opacity(.opacityTextFieldPrompt))
            )
            .textFieldSmall()
            .autocapitalization(.words)
            .accessibilityIdentifier("EditTransactionCategoryView.NameField.TextField")
            HStack {
                Spacer(minLength: 0)
                Text(nameInstructions)
                    .font(.caption2)
                    .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
            }
        }
        .formRow()
    }
    
    @ViewBuilder func SymbolField() -> some View {
        NavigationLink {
            SfSymbolPickerView(selectedSymbol: $symbolString)
        } label: {
            HStack {
                Text("Symbol")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                if let sfSymbol = symbolString {
                    Image(systemName: sfSymbol)
                        .buttonLabelSmall()
                } else {
                    Text("N/A")
                        .buttonLabelSmall()
                }
            }
        }
        .formRow()
        .accessibilityIdentifier("EditTransactionCategoryView.SymbolField.SelectSymbolButton")
    }
}

#Preview("New") {
    NavigationStack {
        EditTransactionCategoryView(
            budget: Budget(info: .sample),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
    }
}

#Preview("Edit") {
    NavigationStack {
        EditTransactionCategoryView(
            budget: Budget(info: .sample),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
        .editing(.init(
            id: Transaction.Category.Id(),
            kind: .income,
            name: .init("Category To Edit")!,
            sfSymbol: .init("pencil.and.outline")!
        ))
    }
}
