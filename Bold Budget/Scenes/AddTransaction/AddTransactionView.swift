//
//  AddTransactionView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import SwiftUI

struct AddTransactionView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var budget: Budget
    
    @State private var category: Transaction.Category? = nil
    @State private var amountDouble: Double = 0
    @State private var transactionDate: Date = .now
    @State private var titleString: String = ""
    @State private var titleInstructions: String = ""
    @State private var locationString: String = ""
    @State private var locationInstructions: String = ""
    @State private var newTagString: String = ""
    @State private var newTagInstructions: String = ""
    @State private var tags: Set<Transaction.Tag> = []

    @State private var showDiscardDialog: Bool = false
    @State private var showTransactionDatePicker: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    private var transaction: Transaction? {
        guard let category = category else { return nil }
        guard let amount = Money(amountDouble) else { return nil }
        guard let date = SimpleDate(date: transactionDate) else { return nil }
        
        var title: Transaction.Title? = nil
        if !titleString.isEmpty {
            guard let tmpTitle = Transaction.Title(titleString) else { return nil }
            title = tmpTitle
        }
        
        var location: Transaction.Location? = nil
        if !locationString.isEmpty {
            guard let tmpLocation = Transaction.Location(locationString) else { return nil }
            location = tmpLocation
        }
        
        return .init(
            id: Transaction.Id(),
            title: title,
            amount: amount,
            date: date,
            category: category,
            location: location,
            tags: tags
        )
    }
    
    private var isFormComplete: Bool { transaction != nil }
    
    private var hasFormChanged: Bool {
        category != nil ||
        amountDouble != 0 ||
        !titleString.isEmpty
    }
    
    private func setTitleInstructions(_ titleString: String) {
        withAnimation(.snappy) {
            if titleString.isEmpty { titleInstructions = ""; return }
            if titleString.count < Transaction.Title.minTextLength { titleInstructions = "Too short"; return }
            if titleString.count > Transaction.Title.maxTextLength { titleInstructions = "Too long"; return }
            titleInstructions = "\(titleString.count)/\(Transaction.Title.maxTextLength)"
        }
    }
    
    private func setLocationInstructions(_ locationString: String) {
        withAnimation(.snappy) {
            if locationString.isEmpty { locationInstructions = ""; return }
            if locationString.count < Transaction.Location.minTextLength { locationInstructions = "Too short"; return }
            if locationString.count > Transaction.Location.maxTextLength { locationInstructions = "Too long"; return }
            locationInstructions = "\(locationString.count)/\(Transaction.Location.maxTextLength)"
        }
    }
    
    private func setNewTagInstructions(_ newTagString: String) {
        withAnimation(.snappy) {
            if newTagString.isEmpty { newTagInstructions = ""; return }
            if newTagString.count < Transaction.Tag.minTextLength { newTagInstructions = "Too short"; return }
            if newTagString.count > Transaction.Tag.maxTextLength { newTagInstructions = "Too long"; return }
            newTagInstructions = "\(newTagString.count)/\(Transaction.Tag.maxTextLength)"
        }
    }
    
    private func saveNewTag() {
        if let tag = Transaction.Tag(newTagString) {
            tags.insert(tag)
            newTagString = ""
        } else {
            newTagInstructions = String(localized: "Invalid Tag")
        }
    }
    
    private func remove(tag: Transaction.Tag) {
        tags.remove(tag)
    }
    
    private func saveTransaction() {
        guard let transaction = transaction else { return }
        budget.add(transaction: transaction)
        dismiss()
    }
    
    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }

    var body: some View {
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
                LocationField()
                TagsField()
            } header: {
                Text("Optional")
                    .foregroundStyle(Color.text)
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
        .navigationTitle("Add Transaction")
        .navigationBarBackButtonHidden()
        .foregroundStyle(Color.text)
        .background(Color.background)
        .onChange(of: titleString) { _, titleString in setTitleInstructions(titleString) }
        .onChange(of: locationString) { _, locationString in setLocationInstructions(locationString) }
        .onChange(of: newTagString) { _, newTagString in setNewTagInstructions(newTagString) }
        .alert(alertMessage, isPresented: $showAlert) {}
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
            if hasFormChanged {
                showDiscardDialog = true
            } else {
                dismiss()
            }
        } label: {
            Image(systemName: "chevron.backward")
        }
        .accessibilityIdentifier("AddTransactionView.Toolbar.DismissButton")
        .confirmationDialog("Discard this transaction?", isPresented: $showDiscardDialog, titleVisibility: .visible) {
            DiscardButton()
            CancelDiscardButton()
        }
    }
    
    @ViewBuilder func DiscardButton() -> some View {
        Button(role: .destructive) {
            dismiss()
        } label: {
            Text("Discard")
        }
    }
    
    @ViewBuilder func CancelDiscardButton() -> some View {
        Button(role: .cancel) {
        } label: {
            Text("Cancel")
        }
    }
    
    @ViewBuilder func SaveButton() -> some View {
        Button {
            saveTransaction()
        } label: {
            Image(systemName: "checkmark")
        }
        .opacity(isFormComplete ? 1 : .opacityButtonBackground)
        .disabled(!isFormComplete)
        .accessibilityIdentifier("AddTransactionView.Toolbar.SaveButton")
    }
    
    @ViewBuilder func CategoryField() -> some View {
        NavigationLink {
            TransactionCategoryPickerView(
                budget: budget,
                selectedCategory: $category
            )
            .pickerMode(.pickerAndEditor)
        } label: {
            HStack {
                Text("Category")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                if let category = category {
                    HStack {
                        Image(systemName: category.sfSymbol.value)
                        Text(category.name.value)
                    }
                    .buttonLabelSmall()
                } else {
                    Text(category?.name.value ?? "N/A")
                        .buttonLabelSmall()
                }
            }
        }
        .formRow()
        .accessibilityIdentifier("AddTransactionView.CategoryField.SelectCategoryButton")
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
            .accessibilityIdentifier("AddTransactionView.AmountField.TextField")
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
                    .foregroundStyle(Color.text.opacity(0.75))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
            }
            TextField("Title",
                      text: $titleString,
                      prompt: Text("Milk Tea, Movie Tickets, etc...").foregroundStyle(Color.text.opacity(0.7))
            )
            .textFieldSmall()
            .autocapitalization(.words)
            .accessibilityIdentifier("AddTransactionView.TitleField.TextField")
        }
        .formRow()
    }
    
    @ViewBuilder func LocationField() -> some View {
        VStack {
            HStack {
                Text("Location")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                Text(locationInstructions)
                    .font(.caption2)
                    .foregroundStyle(Color.text.opacity(0.75))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
            }
            TextField("Location",
                      text: $locationString,
                      prompt: Text(Transaction.Location.sample.value).foregroundStyle(Color.text.opacity(0.7))
            )
            .textFieldSmall()
            .accessibilityIdentifier("AddTransactionView.LocationField.TextField")
        }
        .formRow()
    }
    
    @ViewBuilder func TagsField() -> some View {
        VStack {
            HStack {
                Text("Tags")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                Text(newTagInstructions)
                    .font(.caption2)
                    .foregroundStyle(Color.text.opacity(0.75))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
            }
            HStack {
                TextField("Tags",
                          text: $newTagString,
                          prompt: Text(Transaction.Tag.sample.value).foregroundStyle(Color.text.opacity(0.7))
                )
                .textFieldSmall()
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("AddTransactionView.TagsField.TextField")
                SaveNewTagButton()
            }
        }
        .formRow()
        ForEach(tags.sorted { $0.value < $1.value }) { tag in
            TagRow(tag)
        }
    }
    
    @ViewBuilder func SaveNewTagButton() -> some View {
        Button {
            saveNewTag()
        } label: {
            Text("Add")
                .buttonLabelMedium()
        }
        .accessibilityIdentifier("AddTransactionView.TagsField.SaveNewTagButton")
    }
    
    @ViewBuilder func TagRow(_ tag: Transaction.Tag) -> some View {
        HStack {
            Image(systemName: "xmark")
                .buttonSymbolCircleSmall()
                .onTapGesture {
                    remove(tag: tag)
                }
            TransactionTagView(tag)
        }
        .formRow()
    }
}

#Preview {
    NavigationStack {
        AddTransactionView(budget: Budget(info: .sample))
    }
}
