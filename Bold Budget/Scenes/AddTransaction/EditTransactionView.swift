//
//  EditTransactionView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import SwiftUI
import SwinjectAutoregistration

struct EditTransactionView: View {
    
    enum Focus {
        case amount
        case title
        case location
        case tags
    }
    
    private struct OptionalTransaction: Equatable {
        let transaction: Transaction?
        static let none: OptionalTransaction = .init(transaction: nil)
    }
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var budget: Budget
    
    private var transactionToEdit: OptionalTransaction = .none
    private var onTransactionEditComplete: ((Transaction) -> Void)?
    
    @FocusState private var focus: Focus?
    
    @State private var screenTitle: String = String(localized: "Add Transaction")
    @State private var categoryId: Transaction.Category.Id? = nil
    @State private var amountDouble: Double = 0
    @State private var transactionDate: Date = .now
    @State private var titleString: String = ""
    @State private var titleInstructions: String = ""
    @State private var locationString: String = ""
    @State private var locationInstructions: String = ""
    @State private var newTagString: String = ""
    @State private var newTagInstructions: String = ""
    @State private var tags: Set<Transaction.Tag> = []

    @State private var subscriptionLevel: SubscriptionLevel? = nil
    @State private var showDiscardDialog: Bool = false
    @State private var showTransactionDatePicker: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    private let subscriptionManager: SubscriptionLevelProvider
    
    init(budget: Budget) {
        self.init(
            budget: budget,
            subscriptionManager: iocContainer~>SubscriptionLevelProvider.self
        )
    }
    
    init(
        budget: Budget,
        subscriptionManager: SubscriptionLevelProvider
    ) {
        self._budget = .init(wrappedValue: budget)
        self.subscriptionManager = subscriptionManager
    }
    
    public func editing(_ transaction: Transaction) -> EditTransactionView {
        var view = self
        view.transactionToEdit = .init(transaction: transaction)
        return view
    }
    
    public func onTransactionSaved(perform action: @escaping (Transaction) -> Void) -> EditTransactionView {
        var view = self
        view.onTransactionEditComplete = action
        return view
    }
    
    private var transaction: Transaction? {
        guard let categoryId = categoryId else { return nil }
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
            id: transactionToEdit.transaction?.id ?? Transaction.Id(),
            title: title,
            amount: amount,
            date: date,
            categoryId: categoryId,
            location: location,
            tags: tags
        )
    }
    
    private var isEditing: Bool { transactionToEdit.transaction != nil }
    
    private var isFormComplete: Bool { transaction != nil }
    
    private var hasFormChanged: Bool {
        categoryId != nil ||
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
        budget.save(transaction: transaction)
        onTransactionEditComplete?(transaction)
        dismiss()
    }
    
    private func populateFields(_ transaction: OptionalTransaction) {
        guard let transaction = transaction.transaction else { return }
        screenTitle = String(localized: "Edit Transaction")
        categoryId = transaction.categoryId
        amountDouble = transaction.amount.amount
        transactionDate = transaction.date.toDate() ?? .now
        titleString = transaction.title?.value ?? ""
        locationString = transaction.location?.value ?? ""
        tags = transaction.tags
    }
    
    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }

    var body: some View {
        ScrollViewReader { scrollview in
            Form {
                AdSection()
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
            .onChange(of: focus) { _, newFocus in scrollview.scrollTo(newFocus, anchor: .top) }
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
        .onChange(of: transactionToEdit, initial: true) { _, transaction in populateFields(transaction) }
        .onChange(of: titleString) { _, titleString in setTitleInstructions(titleString) }
        .onChange(of: locationString) { _, locationString in setLocationInstructions(locationString) }
        .onChange(of: newTagString) { _, newTagString in setNewTagInstructions(newTagString) }
        .alert(alertMessage, isPresented: $showAlert) {}
        .onReceive(subscriptionManager.subscriptionLevelPublisher) { subscriptionLevel = $0 }
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
        .accessibilityIdentifier("EditTransactionView.Toolbar.DismissButton")
        .confirmationDialog(isEditing ? "Discard changes to this transaction?" : "Discard this transaction?", isPresented: $showDiscardDialog, titleVisibility: .visible) {
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
        .accessibilityIdentifier("EditTransactionView.Toolbar.SaveButton")
    }
    
    @ViewBuilder func AdSection() -> some View {
        if subscriptionLevel == SubscriptionLevel.none {
            Section {
                SimpleBannerAdView()
            }
        }
    }
    
    @ViewBuilder func CategoryField() -> some View {
        NavigationLink {
            TransactionCategoryPickerView(
                budget: budget,
                selectedCategoryId: $categoryId
            )
            .pickerMode(.pickerAndEditor)
        } label: {
            HStack {
                Text("Category")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                if let categoryId = categoryId {
                    let category = budget.getCategoryBy(id: categoryId)
                    HStack {
                        Image(systemName: category.sfSymbol.value)
                        Text(category.name.value)
                    }
                    .buttonLabelSmall()
                } else {
                    Text("N/A")
                        .buttonLabelSmall()
                }
            }
        }
        .formRow()
        .accessibilityIdentifier("EditTransactionView.CategoryField.SelectCategoryButton")
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
            .focused($focus, equals: Focus.amount)
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
            .textFieldSmall()
            .frame(width: 128)
            .accessibilityIdentifier("EditTransactionView.AmountField.TextField")
        }
        .formRow()
        .id(Focus.amount)
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
                    .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
            }
            TextField("Title",
                      text: $titleString,
                      prompt: Text("Milk Tea, Movie Tickets, etc...").foregroundStyle(Color.text.opacity(.opacityTextFieldPrompt))
            )
            .focused($focus, equals: Focus.title)
            .textFieldSmall()
            .autocapitalization(.words)
            .accessibilityIdentifier("EditTransactionView.TitleField.TextField")
        }
        .formRow()
        .id(Focus.title)
    }
    
    @ViewBuilder func LocationField() -> some View {
        VStack {
            HStack {
                Text("Location")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                Text(locationInstructions)
                    .font(.caption2)
                    .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
            }
            TextField("Location",
                      text: $locationString,
                      prompt: Text(Transaction.Location.sample.value).foregroundStyle(Color.text.opacity(.opacityTextFieldPrompt))
            )
            .focused($focus, equals: Focus.location)
            .textFieldSmall()
            .accessibilityIdentifier("EditTransactionView.LocationField.TextField")
        }
        .formRow()
        .id(Focus.location)
    }
    
    @ViewBuilder func TagsField() -> some View {
        VStack {
            HStack {
                Text("Tags")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                Text(newTagInstructions)
                    .font(.caption2)
                    .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
            }
            HStack {
                TextField("Tags",
                          text: $newTagString,
                          prompt: Text(Transaction.Tag.sample.value).foregroundStyle(Color.text.opacity(.opacityTextFieldPrompt))
                )
                .focused($focus, equals: Focus.tags)
                .textFieldSmall()
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("EditTransactionView.TagsField.TextField")
                SaveNewTagButton()
            }
        }
        .formRow()
        .id(Focus.tags)
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
        .accessibilityIdentifier("EditTransactionView.TagsField.SaveNewTagButton")
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
        EditTransactionView(budget: Budget(info: .sample))
    }
}
