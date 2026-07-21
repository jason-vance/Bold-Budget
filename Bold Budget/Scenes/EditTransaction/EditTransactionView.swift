//
//  EditTransactionView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import SwiftUI
import SwinjectAutoregistration

struct EditTransactionView: View {
    
    private struct OptionalTransaction: Equatable {
        let transaction: Transaction?
        static let none: OptionalTransaction = .init(transaction: nil)
    }
    
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?
    
    @StateObject var budget: Budget
    
    private var transactionToEdit: OptionalTransaction = .none
    private var onTransactionEditComplete: ((Transaction) -> Void)?
    
    @State private var screenTitle: String = String(localized: "Add Transaction")
    @State private var kind: Transaction.Kind = .expense
    @State private var categoryId: Transaction.Category.Id? = nil
    @State private var accountId: Account.Id? = nil
    @State private var fromAccountId: Account.Id? = nil
    @State private var toAccountId: Account.Id? = nil
    @State private var amount: Money = .zero
    @State private var showAmountEntryView: Bool = false
    @State private var transactionDate: Date = .now
    @State private var titleString: String = ""
    @State private var showTitleEntryView: Bool = false
    @State private var locationString: String = ""
    @State private var showLocationEntryView: Bool = false
    @State private var tags: Set<Transaction.Tag> = []
    @State private var showTagsEditorView: Bool = false
    
    @State private var suggestions: TransactionPropertySuggestions = .empty

    @State private var hasPopulatedFields: Bool = false
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
    
    private var partialTransaction: PartialTransaction {
        PartialTransaction(
            title: Transaction.Title(titleString),
            amount: amount == .zero ? nil : amount,
            categoryId: categoryId,
            location: Transaction.Location(locationString),
            tags: tags
        )
    }
    
    private var transaction: Transaction? {
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

        let id = transactionToEdit.transaction?.id ?? Transaction.Id()

        if kind == .transfer {
            guard amount != .zero else { return nil }
            guard let fromAccountId, let toAccountId, fromAccountId != toAccountId else { return nil }
            return .init(
                id: id,
                title: title,
                amount: amount,
                date: date,
                categoryId: Transaction.Category.transferId,
                location: location,
                tags: tags,
                kind: .transfer,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId
            )
        }

        guard let categoryId = categoryId else { return nil }
        return .init(
            id: id,
            title: title,
            amount: amount,
            date: date,
            categoryId: categoryId,
            location: location,
            tags: tags,
            kind: kind,
            accountId: accountId
        )
    }
    
    private var isEditing: Bool { transactionToEdit.transaction != nil }
    
    private var isFormComplete: Bool { transaction != nil }
    
    private var hasFormChanged: Bool {
        categoryId != nil ||
        amount != .zero ||
        !titleString.isEmpty ||
        accountId != nil ||
        fromAccountId != nil ||
        toAccountId != nil
    }
    
    private var transactionTitleInstructions: String {
        if titleString.isEmpty { return "" }
        if let _ = Transaction.Title(titleString) { return "" }
        return "Invalid Title"
    }
    
    private var transactionLocationInstructions: String {
        if locationString.isEmpty { return "" }
        if let _ = Transaction.Location(locationString) { return "" }
        return "Invalid Location"
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
        guard !hasPopulatedFields else { return }
        guard let transaction = transaction.transaction else { return }
        
        screenTitle = String(localized: "Edit Transaction")
        kind = transaction.kind
        categoryId = transaction.isTransfer ? nil : transaction.categoryId
        accountId = transaction.accountId
        fromAccountId = transaction.fromAccountId
        toAccountId = transaction.toAccountId
        amount = transaction.amount
        transactionDate = transaction.date.toDate() ?? .now
        titleString = transaction.title?.value ?? ""
        locationString = transaction.location?.value ?? ""
        tags = transaction.tags

        hasPopulatedFields = true
    }
    
    private func getSuggestions(for partialTransaction: PartialTransaction) {
        Task {
            let suggestions = TransactionPropertySuggestions.from(
                partialTransaction: partialTransaction,
                historicalTransactions: budget.transactions.map(\.value)
            )
            print("suggestions.categoryIds.count: \(suggestions.categoryIds.count)")
            
            await MainActor.run {
                self.suggestions = suggestions
            }
        }
    }
    
    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }

    var body: some View {
        Form {
            AdSection()
            Section {
                KindField()
                if kind == .transfer {
                    AccountField(title: "From", selection: $fromAccountId, exclude: toAccountId)
                    AccountField(title: "To", selection: $toAccountId, exclude: fromAccountId)
                } else {
                    CategoryField()
                    AccountField(title: "Account", selection: $accountId, exclude: nil)
                }
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
        .animation(.snappy, value: suggestions)
        .animation(.snappy, value: partialTransaction)
        .animation(.snappy, value: kind)
        .scrollDismissesKeyboard(.immediately)
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .toolbar { Toolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(screenTitle)
        .navigationBarBackButtonHidden()
        .foregroundStyle(Color.text)
        .background(Color.background.ignoresSafeArea())
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .onChange(of: transactionToEdit, initial: true) { _, new in populateFields(new) }
        .onChange(of: partialTransaction, initial: true) { old, new in getSuggestions(for: new) }
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
                NativeAdListRow(ad: $ad, size: .small)
                    .listRow()
            }
        }
    }
    
    @ViewBuilder func KindField() -> some View {
        Picker("Type", selection: $kind) {
            ForEach(Transaction.Kind.allCases, id: \.self) { kind in
                Text(kind.name).tag(kind)
            }
        }
        .pickerStyle(.segmented)
        .listRow()
        .accessibilityIdentifier("EditTransactionView.KindField")
    }

    private func sortedAccounts(in accountClass: Account.Class, excluding excluded: Account.Id?) -> [Account] {
        budget.accounts.values
            .filter { $0.accountClass == accountClass && $0.id != excluded }
            .sorted { $0.name.value < $1.name.value }
    }

    @ViewBuilder func AccountField(title: LocalizedStringKey, selection: Binding<Account.Id?>, exclude: Account.Id?) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.text)
            Spacer(minLength: 0)
            Menu {
                Button {
                    selection.wrappedValue = nil
                } label: {
                    HStack {
                        Text("None")
                        if selection.wrappedValue == nil { Image(systemName: "checkmark") }
                    }
                }
                ForEach(Account.Class.allCases, id: \.self) { accountClass in
                    let accounts = sortedAccounts(in: accountClass, excluding: exclude)
                    if !accounts.isEmpty {
                        Section(accountClass.pluralName) {
                            ForEach(accounts) { account in
                                Button {
                                    selection.wrappedValue = account.id
                                } label: {
                                    HStack {
                                        Image(systemName: account.kind.sfSymbol)
                                        Text(account.name.value)
                                        if selection.wrappedValue == account.id { Image(systemName: "checkmark") }
                                    }
                                }
                            }
                        }
                    }
                }
            } label: {
                AccountFieldLabel(selection.wrappedValue)
            }
        }
        .listRow()
        .accessibilityIdentifier("EditTransactionView.AccountField")
    }

    @ViewBuilder private func AccountFieldLabel(_ id: Account.Id?) -> some View {
        if let id, let account = budget.accounts[id] {
            HStack {
                Image(systemName: account.kind.sfSymbol)
                Text(account.name.value)
            }
            .buttonLabelSmall()
        } else {
            Text(kind == .transfer ? "Select" : "None")
                .buttonLabelSmall()
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
                CategoryButtonLabel(categoryId)
            }
        }
        .listRow()
        .listRowSeparator(categoryId == nil ? .hidden : .visible)
        .accessibilityIdentifier("EditTransactionView.CategoryField.SelectCategoryButton")
        if categoryId == nil && !suggestions.categoryIds.isEmpty {
            let categories = suggestions.categoryIds.map { budget.getCategoryBy(id: $0) }
            HorizontalScrollingSuggestions(items: categories) { category in
                Button {
                    self.categoryId = category.id
                } label: {
                    CategoryButtonLabel(category.id)
                }
            }
        }
    }
    
    @ViewBuilder private func CategoryButtonLabel(_ categoryId: Transaction.Category.Id?) -> some View {
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
    
    @ViewBuilder private func HorizontalScrollingSuggestions<Item: Identifiable, Content: View>(
        items: [Item],
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(items) { item in
                    content(item)
                        .overlay(alignment: .topLeading) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(Color.text)
                                .font(.footnote)
                                .offset(x: -.paddingVerticalButtonXSmall/2, y: -.paddingVerticalButtonXSmall)
                                .rotationEffect(.degrees(-25))
                        }
                }
            }
            .padding(.horizontal, .paddingHorizontalButtonMedium)
            .padding(.vertical, .paddingVerticalButtonXSmall)
        }
        .listRowBackground(Color.text.opacity(.opacityButtonBackground))
        .listRowSeparatorTint(Color.text.opacity(.opacityButtonBackground))
        .listRowInsets(.init(top: .paddingVerticalButtonXSmall,
                             leading: 0,
                             bottom: .paddingVerticalButtonXSmall,
                             trailing: 0))
    }
    
    @ViewBuilder func AmountField() -> some View {
        HStack {
            Text("Amount")
                .foregroundStyle(Color.text)
            Spacer(minLength: 0)
            Button {
                showAmountEntryView = true
            } label: {
                HStack {
                    Spacer(minLength: 0)
                    Text(amount.formatted())
                        .multilineTextAlignment(.trailing)
                }
            }
            .frame(width: 128)
            .textFieldSmall()
            .accessibilityIdentifier("EditTransactionView.AmountField.TextField")
        }
        .listRow()
        .listRowSeparator(amount.amount == .zero ? .hidden : .visible)
        .fullScreenCover(isPresented: $showAmountEntryView) {
            TransactionAmountEntryView(
                amount: $amount,
                budget: budget
            )
        }
        if amount.amount == .zero && !suggestions.amounts.isEmpty {
            HorizontalScrollingSuggestions(items: suggestions.amounts) { amount in
                Button {
                    self.amount = amount
                } label: {
                    Text(amount.formatted())
                        .buttonLabelSmall()
                }
            }
        }
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
        .listRow()
    }
    
    @ViewBuilder func TransactionDatePicker() -> some View {
        if showTransactionDatePicker {
            DatePicker(
                "Date",
                selection: $transactionDate,
                in: Date.distantPast...(Date.distantFuture),
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(Color.text)
            .listRow()
        }
    }
    
    @ViewBuilder func TitleField() -> some View {
        VStack {
            HStack {
                Text("Title")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                Text(transactionTitleInstructions)
                    .font(.caption2)
                    .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
            }
            Button {
                showTitleEntryView = true
            } label: {
                HStack {
                    Text(titleString.isEmpty ? Transaction.Title.sample.value : titleString)
                        .opacity(titleString.isEmpty ? .opacityTextFieldPrompt : 1)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            .textFieldSmall()
            .accessibilityIdentifier("EditTransactionView.TitleField.TextField")
        }
        .listRow()
        .listRowSeparator(titleString.isEmpty ? .hidden : .visible)
        .fullScreenCover(isPresented: $showTitleEntryView) {
            TransactionTitleEntryView(
                titleString: $titleString,
                budget: budget
            )
        }
        if titleString.isEmpty && !suggestions.titles.isEmpty {
            HorizontalScrollingSuggestions(items: suggestions.titles) { title in
                Button {
                    self.titleString = title.value
                } label: {
                    Text(title.value)
                        .buttonLabelSmall()
                }
            }
        }
    }
    
    @ViewBuilder func LocationField() -> some View {
        VStack {
            HStack {
                Text("Location")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                Text(transactionLocationInstructions)
                    .font(.caption2)
                    .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
            }
            Button {
                showLocationEntryView = true
            } label: {
                HStack {
                    Text(locationString.isEmpty ? Transaction.Location.sample.value : locationString)
                        .opacity(locationString.isEmpty ? .opacityTextFieldPrompt : 1)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            .textFieldSmall()
            .accessibilityIdentifier("EditTransactionView.LocationField.TextField")
        }
        .listRow()
        .listRowSeparator(locationString.isEmpty ? .hidden : .visible)
        .fullScreenCover(isPresented: $showLocationEntryView) {
            TransactionLocationEntryView(
                locationString: $locationString,
                budget: budget
            )
        }
        if locationString.isEmpty && !suggestions.locations.isEmpty {
            HorizontalScrollingSuggestions(items: suggestions.locations) { location in
                Button {
                    self.locationString = location.value
                } label: {
                    Text(location.value)
                        .buttonLabelSmall()
                }
            }
        }
    }
    
    @ViewBuilder func TagsField() -> some View {
        let suggestedTags = suggestions.tags.filter { !tags.contains($0) }
        VStack {
            HStack {
                Text("Tags")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                AddTagsButton()
            }
        }
        .listRow()
        .listRowSeparator(!suggestedTags.isEmpty ? .hidden : .visible)
        if !suggestedTags.isEmpty {
            HorizontalScrollingSuggestions(items: suggestedTags) { tag in
                Button {
                    tags.insert(tag)
                } label: {
                    TransactionTagView(tag)
                }
            }
        }
        ForEach(tags.sorted { $0.value < $1.value }) { tag in
            TagRow(tag)
        }
    }
    
    @ViewBuilder func AddTagsButton() -> some View {
        Button {
            showTagsEditorView = true
        } label: {
            AddTagButtonLabel()
        }
        .accessibilityIdentifier("EditTransactionView.TagsField.AddTagsButton")
        .fullScreenCover(isPresented: $showTagsEditorView) {
            TagsEditorView(tags: $tags, budget: budget)
        }
    }
    
    @ViewBuilder private func AddTagButtonLabel() -> some View {
        HStack {
            Image(systemName: "tag")
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "plus")
                        .font(.system(size: 8))
                        .bold()
                        .foregroundStyle(Color.background)
                        .padding(.borderWidthThin)
                        .background {
                            Circle()
                                .foregroundStyle(Color.text)
                        }
                }
        }
        .buttonLabelSmall()
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
        .listRow()
    }
}

#Preview {
    NavigationStack {
        EditTransactionView(budget: Budget(info: .sample))
    }
}
