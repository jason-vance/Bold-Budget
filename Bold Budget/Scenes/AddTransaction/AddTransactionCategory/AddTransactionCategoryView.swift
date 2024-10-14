//
//  AddTransactionCategoryView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import SwiftUI

struct AddTransactionCategoryView: View {
    
    private struct OptionalCategory: Equatable {
        let category: Transaction.Category?
        static let none: OptionalCategory = .init(category: nil)
    }
    
    @Environment(\.dismiss) private var dismiss
    
    private var categoryToEdit: OptionalCategory = .none
    
    @State private var screenTitle: String = String(localized: "Add Category")
    @State private var kind: Transaction.Category.Kind = .expense
    @State private var symbolString: String? = nil
    @State private var nameString: String = ""
    @State private var nameInstructions: String = ""
    
    public func editing(_ category: Transaction.Category) -> AddTransactionCategoryView {
        var view = self
        view.categoryToEdit = .init(category: category)
        return view
    }
    
    private var category: Transaction.Category? {
        guard let name = Transaction.Category.Name(nameString) else { return nil }
        guard let symbolString = symbolString else { return nil }
        guard let sfSymbol = Transaction.Category.SfSymbol(symbolString) else { return nil }

        return .init(
            id: UUID(),
            kind: kind,
            name: name,
            sfSymbol: sfSymbol
        )
    }
    
    private var isFormComplete: Bool { category != nil }
    
    private func saveCategory() {
        guard let category = category else { return }
        
        if let categoryToEdit = categoryToEdit.category {
            categoryToEdit.kind = category.kind
            categoryToEdit.name = category.name
            categoryToEdit.sfSymbol = category.sfSymbol
        } else {
            guard let saver = iocContainer.resolve(TransactionCategorySaver.self) else { return }
            saver.insert(category: category)
        }
        
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
        print("populating fields")
        screenTitle = String(localized: "Edit Category")
        kind = category.kind
        symbolString = category.sfSymbol.value
        nameString = category.name.value
    }
    
    var body: some View {
        Form {
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
        .navigationBarBackButtonHidden()
        .foregroundStyle(Color.text)
        .background(Color.background)
        .onChange(of: nameString) { _, nameString in setNameInstructions(nameString) }
        .onChange(of: categoryToEdit, initial: true) { _, category in populateFields(category) }
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
        .accessibilityIdentifier("AddTransactionCategoryView.Toolbar.CloseButton")
    }
    
    @ViewBuilder func SaveButton() -> some View {
        Button {
            saveCategory()
        } label: {
            Image(systemName: "checkmark")
        }
        .opacity(isFormComplete ? 1 : .opacityButtonBackground)
        .disabled(!isFormComplete)
        .accessibilityIdentifier("AddTransactionCategoryView.Toolbar.SaveButton")
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
                      prompt: Text("Groceries, Rent, Paycheck, etc...").foregroundStyle(Color.text.opacity(0.7))
            )
            .textFieldSmall()
            .autocapitalization(.words)
            .accessibilityIdentifier("AddTransactionCategoryView.NameField.TextField")
            HStack {
                Spacer(minLength: 0)
                Text(nameInstructions)
                    .font(.caption2)
                    .foregroundStyle(Color.text.opacity( 0.75))
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
        .accessibilityIdentifier("AddTransactionCategoryView.SymbolField.SelectSymbolButton")
    }
}

#Preview("New") {
    NavigationStack {
        AddTransactionCategoryView()
    }
}

#Preview("Edit") {
    NavigationStack {
        AddTransactionCategoryView()
            .editing(.init(
                id: UUID(),
                kind: .income,
                name: .init("Category To Edit")!,
                sfSymbol: .init("pencil.and.outline")!
            ))
    }
}
