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

    private static let maxDigits = 12 // caps entry at $9,999,999,999.99

    @Environment(\.dismiss) private var dismiss

    @StateObject var budget: Budget

    private var transactionToEdit: OptionalTransaction = .none
    private var onTransactionEditComplete: ((Transaction) -> Void)?

    @State private var screenTitle: String = String(localized: "Add Transaction")
    @State private var kind: Transaction.Kind = .expense
    @State private var categoryId: Transaction.Category.Id? = nil
    @State private var accountId: Account.Id? = nil
    @State private var fromAccountId: Account.Id? = nil
    @State private var toAccountId: Account.Id? = nil
    /// Raw digits entered so far, read right-to-left as cents (e.g. "1234" == $12.34).
    @State private var digits: String = ""
    @State private var shakeAmount: Bool = false
    @State private var transactionDate: Date = .now
    @State private var titleString: String = ""
    @State private var showTitleEntryView: Bool = false
    @State private var locationString: String = ""
    @State private var showLocationEntryView: Bool = false
    @State private var tags: Set<Transaction.Tag> = []
    @State private var showTagsEditorView: Bool = false
    @State private var showDetails: Bool = false
    @State private var showTransactionDatePicker: Bool = false

    @State private var suggestions: TransactionPropertySuggestions = .empty

    @State private var hasPopulatedFields: Bool = false
    @State private var showDiscardDialog: Bool = false

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

    // MARK: - Amount / keypad

    private var amount: Money {
        Money((Double(digits) ?? 0) / 100) ?? .zero
    }

    private func appendDigit(_ digit: String) {
        let candidate = String((digits + digit).drop { $0 == "0" })
        let normalized = candidate.isEmpty ? "0" : candidate
        guard normalized.count <= Self.maxDigits else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            shakeAmount = true
            return
        }
        digits = normalized
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func deleteLastDigit() {
        guard !digits.isEmpty else { return }
        digits = String(digits.dropLast())
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func clearAllDigits() {
        guard !digits.isEmpty else { return }
        digits = ""
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func setAmount(_ money: Money) {
        let cents = Int((money.amount * 100).rounded())
        digits = cents == 0 ? "" : String(cents)
    }

    // MARK: - Model

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
        guard amount != .zero else { return nil }

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

    private var hasDetails: Bool {
        !titleString.isEmpty || !locationString.isEmpty || !tags.isEmpty
    }

    private var addButtonTitle: String {
        if isEditing { return String(localized: "Save") }
        switch kind {
        case .expense: return String(localized: "Add Expense")
        case .income: return String(localized: "Add Income")
        case .transfer: return String(localized: "Add Transfer")
        }
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
        setAmount(transaction.amount)
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

            await MainActor.run {
                self.suggestions = suggestions
            }
        }
    }

    private func tint(for kind: Transaction.Kind) -> Color {
        switch kind {
        case .income: .positive
        case .expense: .text
        case .transfer: .accent
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: .padding) {
            KindSegmented()
            Spacer(minLength: 0)
            AmountDisplay()
            ChipsRow()
            SuggestionsArea()
            Spacer(minLength: 0)
            KeypadGrid(onDigit: appendDigit, onDelete: deleteLastDigit, onClear: clearAllDigits)
            AddButton()
            DetailsButton()
        }
        .padding()
        .toolbar { Toolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(screenTitle)
        .navigationBarBackButtonHidden()
        .foregroundStyle(Color.text)
        .background(Color.background.ignoresSafeArea())
        .sheet(isPresented: $showDetails) { DetailsSheet() }
        .onChange(of: transactionToEdit, initial: true) { _, new in populateFields(new) }
        .onChange(of: partialTransaction, initial: true) { _, new in getSuggestions(for: new) }
        .alert(alertMessage, isPresented: $showAlert) {}
        .animation(.snappy, value: kind)
        .animation(.snappy, value: suggestions)
    }

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            CloseButton()
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
            Button("Discard", role: .destructive) { dismiss() }
            Button("Cancel", role: .cancel) { }
        }
    }

    @ViewBuilder private func KindSegmented() -> some View {
        PillSegmentedControl(
            selection: $kind,
            options: Transaction.Kind.allCases,
            title: { $0.name },
            tint: { tint(for: $0) }
        )
        .accessibilityIdentifier("EditTransactionView.KindField")
    }

    @ViewBuilder private func AmountDisplay() -> some View {
        Text(amount.formatted())
            .font(.system(size: 52, weight: .heavy))
            .foregroundStyle(kind == .expense ? Color.text : tint(for: kind))
            .contentTransition(.numericText())
            .animation(.snappy, value: digits)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .frame(maxWidth: .infinity)
            .shake($shakeAmount)
            .accessibilityIdentifier("EditTransactionView.AmountDisplay")
    }

    // MARK: - Chips

    @ViewBuilder private func ChipsRow() -> some View {
        HStack(spacing: .paddingSmall) {
            if kind == .transfer {
                AccountChip(title: "From", selection: $fromAccountId, exclude: toAccountId)
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(Color.text.opacity(.opacityMutedText))
                AccountChip(title: "To", selection: $toAccountId, exclude: fromAccountId)
            } else {
                AccountChip(title: "Account", selection: $accountId, exclude: nil)
                CategoryChip()
            }
        }
    }

    private func sortedAccounts(in accountClass: Account.Class, excluding excluded: Account.Id?) -> [Account] {
        budget.accounts.values
            .filter { $0.accountClass == accountClass && $0.id != excluded }
            .sorted { $0.name.value < $1.name.value }
    }

    @ViewBuilder private func AccountChip(title: LocalizedStringKey, selection: Binding<Account.Id?>, exclude: Account.Id?) -> some View {
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
            ChipCard(title: title, systemName: selectedAccountSymbol(selection.wrappedValue), text: selectedAccountText(selection.wrappedValue))
        }
        .accessibilityIdentifier("EditTransactionView.AccountChip")
    }

    private func selectedAccountSymbol(_ id: Account.Id?) -> String {
        guard let id, let account = budget.accounts[id] else { return "building.columns" }
        return account.kind.sfSymbol
    }

    private func selectedAccountText(_ id: Account.Id?) -> String {
        if let id, let account = budget.accounts[id] { return account.name.value }
        return String(localized: "None")
    }

    @ViewBuilder private func CategoryChip() -> some View {
        NavigationLink {
            TransactionCategoryPickerView(
                budget: budget,
                selectedCategoryId: $categoryId
            )
            .pickerMode(.pickerAndEditor)
        } label: {
            let category = categoryId.map { budget.getCategoryBy(id: $0) }
            ChipCard(
                title: "Category",
                systemName: category?.sfSymbol.value ?? "square.grid.2x2",
                text: category?.name.value ?? String(localized: "Choose")
            )
        }
        .accessibilityIdentifier("EditTransactionView.CategoryChip")
    }

    @ViewBuilder private func ChipCard(title: LocalizedStringKey, systemName: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .textCase(.uppercase)
                .kerning(0.5)
                .foregroundStyle(Color.text.opacity(0.5))
            HStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.caption)
                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(.paddingSmall, cornerRadius: .cornerRadiusSmall)
    }

    // MARK: - Suggestions

    @ViewBuilder private func SuggestionsArea() -> some View {
        if amount == .zero, !suggestions.amounts.isEmpty {
            SuggestionScroller(items: suggestions.amounts) { money in
                Button { setAmount(money) } label: {
                    Text(money.formatted()).buttonLabelSmall()
                }
            }
        } else if kind != .transfer, categoryId == nil, !suggestions.categoryIds.isEmpty {
            let categories = suggestions.categoryIds.map { budget.getCategoryBy(id: $0) }
            SuggestionScroller(items: categories) { category in
                Button { categoryId = category.id } label: {
                    HStack {
                        Image(systemName: category.sfSymbol.value)
                        Text(category.name.value)
                    }
                    .buttonLabelSmall()
                }
            }
        }
    }

    @ViewBuilder private func SuggestionScroller<Item: Identifiable, Content: View>(
        items: [Item],
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .paddingSmall) {
                ForEach(items) { item in
                    content(item)
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(height: 40)
    }

    // MARK: - Actions

    @ViewBuilder private func AddButton() -> some View {
        Button {
            saveTransaction()
        } label: {
            PrimaryButtonLabel(title: addButtonTitle, enabled: isFormComplete)
        }
        .disabled(!isFormComplete)
        .accessibilityIdentifier("EditTransactionView.Toolbar.SaveButton")
    }

    @ViewBuilder private func DetailsButton() -> some View {
        Button {
            showDetails = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "slider.horizontal.3")
                Text("Details")
                if hasDetails {
                    Circle().frame(width: 5, height: 5)
                }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.text.opacity(.opacityMutedText))
        }
        .accessibilityIdentifier("EditTransactionView.DetailsButton")
    }

    // MARK: - Details sheet

    @ViewBuilder private func DetailsSheet() -> some View {
        NavigationStack {
            Form {
                Section {
                    TitleField()
                    LocationField()
                    TagsField()
                } header: {
                    Text("Details")
                        .foregroundStyle(Color.text)
                }
                Section {
                    TransactionDateField()
                    TransactionDatePicker()
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Details")
            .foregroundStyle(Color.text)
            .background(Color.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showDetails = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.background)
    }

    @ViewBuilder private func TransactionDateField() -> some View {
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
        .listRow()
    }

    @ViewBuilder private func TransactionDatePicker() -> some View {
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

    @ViewBuilder private func TitleField() -> some View {
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
        .fullScreenCover(isPresented: $showTitleEntryView) {
            TransactionTitleEntryView(
                titleString: $titleString,
                budget: budget
            )
        }
    }

    @ViewBuilder private func LocationField() -> some View {
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
        .fullScreenCover(isPresented: $showLocationEntryView) {
            TransactionLocationEntryView(
                locationString: $locationString,
                budget: budget
            )
        }
    }

    @ViewBuilder private func TagsField() -> some View {
        VStack {
            HStack {
                Text("Tags")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                AddTagsButton()
            }
        }
        .listRow()
        ForEach(tags.sorted { $0.value < $1.value }) { tag in
            TagRow(tag)
        }
    }

    @ViewBuilder private func AddTagsButton() -> some View {
        Button {
            showTagsEditorView = true
        } label: {
            HStack {
                Image(systemName: "tag")
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "plus")
                            .font(.system(size: 8))
                            .bold()
                            .foregroundStyle(Color.background)
                            .padding(.borderWidthThin)
                            .background { Circle().foregroundStyle(Color.text) }
                    }
            }
            .buttonLabelSmall()
        }
        .accessibilityIdentifier("EditTransactionView.TagsField.AddTagsButton")
        .fullScreenCover(isPresented: $showTagsEditorView) {
            TagsEditorView(tags: $tags, budget: budget)
        }
    }

    @ViewBuilder private func TagRow(_ tag: Transaction.Tag) -> some View {
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
        EditTransactionView(budget: .previewSample(accounts: Account.samples))
    }
}
