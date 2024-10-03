//
//  AddTransactionCategoryView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import SwiftUI

struct AddTransactionCategoryView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var symbolString: String? = nil
    @State private var nameString: String = ""
    @State private var nameInstructions: String = ""
    
    @State private var showSymbolPicker: Bool = false
    
    private var category: Transaction.Category? {
        guard let name = Transaction.Category.Name(nameString) else { return nil }
        guard let symbolString = symbolString else { return nil }
        guard let sfSymbol = Transaction.Category.SfSymbol(symbolString) else { return nil }

        return .init(
            name: name,
            sfSymbol: sfSymbol
        )
    }
    
    private var isFormComplete: Bool { category != nil }
    
    private func saveCategory() {
        guard let category = category else { return }
        guard let saver = iocContainer.resolve(TransactionCategorySaver.self) else { return }
        saver.save(category: category)
        dismiss()
    }
    
    private func setNameInstructions(_ nameString: String) {
        withAnimation(.snappy) {
            if nameString.count < Transaction.Category.Name.minTextLength { nameInstructions = "Too short"; return }
            if nameString.count > Transaction.Category.Name.maxTextLength { nameInstructions = "Too long"; return }
            nameInstructions = "\(nameString.count)/\(Transaction.Category.Name.maxTextLength)"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            Form {
                Section {
                    NameField()
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
    }
    
    @ViewBuilder func TopBar() -> some View {
        ScreenTitleBar(
            primaryContent: { Text("Add Category") },
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
    
    @ViewBuilder func NameField() -> some View {
        VStack {
            Text("Name")
                .foregroundStyle(Color.text)
            TextField("Name",
                      text: $nameString,
                      prompt: Text("Groceries, Rent, etc...").foregroundStyle(Color.text.opacity(0.7))
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

#Preview {
    AddTransactionCategoryView()
}
