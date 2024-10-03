//
//  AddTransactionView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import SwiftUI

struct AddTransactionView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var category: Transaction.Category? = nil
    @State private var amountDouble: Double = 0
    @State private var transactionDate: Date = .now
    @State private var titleString: String = ""
    @State private var titleInstructions: String = ""
    
    @State private var showCategoryPicker: Bool = false
    @State private var showTransactionDatePicker: Bool = false
    
    private var transaction: Transaction? {
        guard let category = category else { return nil }
        guard let amount = Money(amountDouble) else { return nil }
        
        var title: Transaction.Title? = nil
        if !titleString.isEmpty {
            guard let tmpTitle = Transaction.Title(titleString) else { return nil }
            title = tmpTitle
        }
        
        return .init(
            id: UUID(),
            title: title,
            amount: amount,
            date: transactionDate,
            category: category
        )
    }
    
    private var isFormComplete: Bool { transaction != nil }
    
    private func setTitleInstructions(_ titleString: String) {
        withAnimation(.snappy) {
            if titleString.isEmpty { titleInstructions = ""; return }
            if titleString.count < Transaction.Title.minTextLength { titleInstructions = "Too short"; return }
            if titleString.count > Transaction.Title.maxTextLength { titleInstructions = "Too long"; return }
            titleInstructions = "\(titleString.count)/\(Transaction.Title.maxTextLength)"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            Form {
                Section {
                    CategoryField()
                    AmountField()
                    TransactionDateField()
                    TransactionDatePicker()
                } header: {
                    Text("Required")
                        .foregroundStyle(Color.text)
                }
                Section {
                    TitleField()
                } header: {
                    Text("Optional")
                        .foregroundStyle(Color.text)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .background(Color.background)
        .onChange(of: titleString) { _, titleString in setTitleInstructions(titleString) }
    }
    
    @ViewBuilder func TopBar() -> some View {
        ScreenTitleBar(
            primaryContent: { Text("Add Transaction") },
            leadingContent: { CloseButton() },
            trailingContent: { SaveButton() }
        )
    }
    
    //TODO: Add a dicard dialog
    @ViewBuilder func CloseButton() -> some View {
        Button {
            dismiss()
        } label: {
            TitleBarButtonLabel(sfSymbol: "xmark")
        }
    }
    
    @ViewBuilder func SaveButton() -> some View {
        Button {
            //TODO: Save the transaction
        } label: {
            TitleBarButtonLabel(sfSymbol: "checkmark")
        }
        .opacity(isFormComplete ? 1 : .opacityButtonBackground)
        .disabled(!isFormComplete)
    }
    
    @ViewBuilder func CategoryField() -> some View {
        HStack {
            Text("Category")
                .foregroundStyle(Color.text)
            Spacer(minLength: 0)
            Button {
                showCategoryPicker = true
            } label: {
                Text(category?.name ?? "N/A")
                    .buttonLabelSmall()
            }
        }
        .formRow()
        .fullScreenCover(isPresented: $showCategoryPicker) {
            TransactionCategoryPickerView(mode: .pickerAndEditor) { category = $0 }
        }
    }
    
    @ViewBuilder func AmountField() -> some View {
        HStack {
            Text("Amount")
                .foregroundStyle(Color.text)
            Spacer(minLength: 0)
            TextField(Money(0)?.formatted() ?? "$0.00",
                      value: $amountDouble,
                      format: .currency(code: "USD"),
                      prompt: Text(Money(0)?.formatted() ?? "$0.00")
            )
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
            .textFieldSmall()
            .frame(width: 128)
        }
        .formRow()
    }
    
    @ViewBuilder func TransactionDateField() -> some View {
        VStack {
            HStack {
                Text("Date")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                Button {
                    withAnimation(.snappy) { showTransactionDatePicker.toggle() }
                } label: {
                    Text(transactionDate.toBasicUiString())
                        .buttonLabelSmall()
                }
            }
        }
        .formRow()
    }
    
    @ViewBuilder func TransactionDatePicker() -> some View {
        if showTransactionDatePicker {
            DatePicker(
                "Date",
                selection: $transactionDate,
                in: Date.distantPast...(Date.now),
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(Color.text)
            .formRow()
        }
    }
    
    @ViewBuilder func TitleField() -> some View {
        VStack {
            HStack {
                Text("Title")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                Text(titleInstructions)
                    .font(.caption2)
                    .foregroundStyle(Color.text.opacity( 0.75))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
            }
            TextField("Title",
                      text: $titleString,
                      prompt: Text("Milk Tea, Movie Tickets, etc...").foregroundStyle(Color.text.opacity(0.7))
            )
            .textFieldSmall()
        }
        .formRow()
    }
}

#Preview {
    AddTransactionView()
}
