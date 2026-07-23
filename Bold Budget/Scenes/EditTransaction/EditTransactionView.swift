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

    @State private var screenTitle: String = String(localized: "New Transaction")
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
    @State private var showTransactionDatePicker: Bool = false
    @State private var showAddAccount: Bool = false
    @State private var showAddCategory: Bool = false


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

    private var addButtonTitle: String {
        if isEditing { return String(localized: "Save") }
        switch kind {
        case .expense: return String(localized: "Add Expense")
        case .income: return String(localized: "Add Income")
        case .transfer: return String(localized: "Add Transfer")
        }
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

    private func tint(for kind: Transaction.Kind) -> Color {
        switch kind {
        case .income: .positive
        case .expense: .negative
        case .transfer: .brandTeal
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: .padding) {
            Header()
            KindSegmented()
            Spacer(minLength: 0)
            AmountDisplay()
            Spacer(minLength: 0)
            VStack(spacing: 8) {
                TitleChip()
                ChipsRow()
                MerchantDateRow()
            }
            KeypadGrid(onDigit: appendDigit, onDelete: deleteLastDigit, onClear: clearAllDigits)
            AddButton()
            DetailsButton()
        }
        .padding()
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .sheet(isPresented: $showTransactionDatePicker) { DatePickerSheet() }
        .fullScreenCover(isPresented: $showTitleEntryView) {
            TransactionTitleEntryView(titleString: $titleString, budget: budget)
        }
        .fullScreenCover(isPresented: $showLocationEntryView) {
            TransactionLocationEntryView(locationString: $locationString, budget: budget)
        }
        .fullScreenCover(isPresented: $showTagsEditorView) {
            TagsEditorView(tags: $tags, budget: budget)
        }
        .fullScreenCover(isPresented: $showAddAccount) {
            NavigationStack { EditAccountView(budget: budget) }
        }
        .fullScreenCover(isPresented: $showAddCategory) {
            NavigationStack { EditTransactionCategoryView(budget: budget) }
        }
        .onChange(of: transactionToEdit, initial: true) { _, new in populateFields(new) }
        .alert(alertMessage, isPresented: $showAlert) {}
        .animation(.snappy, value: kind)
    }

    /// Custom in-content header instead of a system toolbar, so the Cancel button renders as plain
    /// borderless text (the iOS 26 nav-bar "Liquid Glass" treatment can't be removed per-item).
    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text(screenTitle)
                .font(.headline)
                .foregroundStyle(Color.appText)
            HStack {
                Button("Cancel") {
                    if hasFormChanged {
                        showDiscardDialog = true
                    } else {
                        dismiss()
                    }
                }
                .foregroundStyle(Color.appMutedText)
                .accessibilityIdentifier("EditTransactionView.Toolbar.DismissButton")
                Spacer(minLength: 0)
            }
        }
        .frame(height: .barHeight)
        .confirmationDialog(isEditing ? "Discard changes to this transaction?" : "Discard this transaction?", isPresented: $showDiscardDialog, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Cancel", role: .cancel) { }
        }
    }

    @ViewBuilder private func KindSegmented() -> some View {
        PillSegmentedControl(
            selection: $kind,
            options: [.income, .expense, .transfer],
            title: { $0.name },
            tint: { tint(for: $0) }
        )
        .accessibilityIdentifier("EditTransactionView.KindField")
    }

    @ViewBuilder private func AmountDisplay() -> some View {
        Text(amount.formatted())
            .font(.system(size: 52, weight: .heavy))
            .foregroundStyle(Color.appText)
            .contentTransition(.numericText())
            .animation(.snappy, value: digits)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
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
                    .foregroundStyle(Color.appMutedText)
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
            Divider()
            Button {
                showAddAccount = true
            } label: {
                Label("Add Account", systemImage: "plus")
            }
        } label: {
            ChipCard(
                title: title,
                systemName: selectedAccountSymbol(selection.wrappedValue),
                text: selectedAccountText(selection.wrappedValue),
                isPlaceholder: selection.wrappedValue == nil
            )
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

    private var sortedCategories: [Transaction.Category] {
        budget.transactionCategories.values.sorted { $0.name.value < $1.name.value }
    }

    @ViewBuilder private func CategoryChip() -> some View {
        Menu {
            Button {
                categoryId = nil
            } label: {
                HStack {
                    Text("None")
                    if categoryId == nil { Image(systemName: "checkmark") }
                }
            }
            ForEach(sortedCategories) { category in
                Button {
                    categoryId = category.id
                } label: {
                    HStack {
                        Image(systemName: category.sfSymbol.value)
                        Text(category.name.value)
                        if categoryId == category.id { Image(systemName: "checkmark") }
                    }
                }
            }
            Divider()
            Button {
                showAddCategory = true
            } label: {
                Label("Add Category", systemImage: "plus")
            }
        } label: {
            let category = categoryId.map { budget.getCategoryBy(id: $0) }
            ChipCard(
                title: "Category",
                systemName: category?.sfSymbol.value ?? "square.grid.2x2",
                text: category?.name.value ?? String(localized: "Choose"),
                isPlaceholder: categoryId == nil
            )
        }
        .accessibilityIdentifier("EditTransactionView.CategoryChip")
    }

    // MARK: - Note / merchant / date chips

    @ViewBuilder private func MerchantDateRow() -> some View {
        HStack(spacing: .paddingSmall) {
            if kind != .transfer {
                LocationChip()
            }
            DateChip()
        }
    }

    @ViewBuilder private func DateChip() -> some View {
        Button {
            showTransactionDatePicker = true
        } label: {
            ChipCard(title: "Date", systemName: "calendar", text: transactionDate.toBasicUiString())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("EditTransactionView.DateChip")
    }

    @ViewBuilder private func TitleChip() -> some View {
        Button {
            showTitleEntryView = true
        } label: {
            ChipCard(
                title: "Note",
                systemName: "note.text",
                text: titleString.isEmpty ? String(localized: "Add") : titleString,
                isPlaceholder: titleString.isEmpty
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("EditTransactionView.TitleChip")
    }

    @ViewBuilder private func LocationChip() -> some View {
        Button {
            showLocationEntryView = true
        } label: {
            ChipCard(
                title: "Merchant",
                systemName: "storefront",
                text: locationString.isEmpty ? String(localized: "Add") : locationString,
                isPlaceholder: locationString.isEmpty
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("EditTransactionView.LocationChip")
    }

    @ViewBuilder private func DatePickerSheet() -> some View {
        NavigationStack {
            DatePicker(
                "Date",
                selection: $transactionDate,
                in: Date.distantPast...(Date.distantFuture),
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(Color.brandTeal)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.appBackground.ignoresSafeArea())
            .foregroundStyle(Color.appText)
            .navigationTitle("Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showTransactionDatePicker = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.appBackground)
    }

    @ViewBuilder private func ChipCard(title: LocalizedStringKey, systemName: String, text: String, isPlaceholder: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .textCase(.uppercase)
                .kerning(0.5)
                .foregroundStyle(Color.appMutedText)
            HStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.caption)
                    .foregroundStyle(Color.brandTeal)
                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isPlaceholder ? Color.appMutedText : Color.appText)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.paddingSmall)
        .background {
            RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                .foregroundStyle(Color.appSurface)
        }
    }

    // MARK: - Actions

    @ViewBuilder private func AddButton() -> some View {
        Button {
            saveTransaction()
        } label: {
            PrimaryButtonLabel(
                title: addButtonTitle,
                enabled: isFormComplete,
                background: .brandTeal,
                foreground: .appBackground
            )
        }
        .disabled(!isFormComplete)
        .accessibilityIdentifier("EditTransactionView.Toolbar.SaveButton")
    }

    /// Opens the tag editor directly — no intermediate sheet.
    @ViewBuilder private func DetailsButton() -> some View {
        Button {
            showTagsEditorView = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "tag")
                Text(tags.isEmpty ? "Add Tags" : "\(tags.count) Tag\(tags.count == 1 ? "" : "s")")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.appMutedText)
        }
        .accessibilityIdentifier("EditTransactionView.DetailsButton")
    }
}

#Preview {
    NavigationStack {
        EditTransactionView(budget: .previewSample(accounts: Account.samples))
    }
}
