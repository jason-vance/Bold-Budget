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
    
    @State private var showSymbolPicker: Bool = false
    
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
        guard var category = category else { return }
        if let categoryToEdit = categoryToEdit.category {
            category = .init(
                id: categoryToEdit.id,
                kind: category.kind,
                name: category.name,
                sfSymbol: category.sfSymbol
            )
        }
        guard let saver = iocContainer.resolve(TransactionCategorySaver.self) else { return }
        saver.save(newCategory: category)
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
        VStack(spacing: 0) {
            TopBar()
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
        }
        .background(Color.background)
        .onChange(of: nameString) { _, nameString in setNameInstructions(nameString) }
        .onChange(of: categoryToEdit, initial: true) { _, category in populateFields(category) }
    }
    
    @ViewBuilder func TopBar() -> some View {
        ScreenTitleBar(
            primaryContent: { Text(screenTitle) },
            leadingContent: { CloseButton() },
            trailingContent: { SaveButton() }
        )
    }
    
    @ViewBuilder func CloseButton() -> some View {
        Button {
            dismiss()
        } label: {
            TitleBarButtonLabel(sfSymbol: "xmark")
        }
    }
    
    @ViewBuilder func SaveButton() -> some View {
        Button {
            saveCategory()
        } label: {
            TitleBarButtonLabel(sfSymbol: "checkmark")
        }
        .opacity(isFormComplete ? 1 : .opacityButtonBackground)
        .disabled(!isFormComplete)
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
        HStack {
            Text("Symbol")
                .foregroundStyle(Color.text)
            Spacer(minLength: 0)
            Button {
                showSymbolPicker = true
            } label: {
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
        .fullScreenCover(isPresented: $showSymbolPicker) {
            SfSymbolPickerView { symbolString = $0 }
        }
    }
}

#Preview("New") {
    AddTransactionCategoryView()
}

#Preview("Edit") {
    AddTransactionCategoryView()
        .editing(.init(
            id: UUID(),
            kind: .income,
            name: .init("Category To Edit")!,
            sfSymbol: .init("pencil.and.outline")!
        ))
}
