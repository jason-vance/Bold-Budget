//
//  EditAccountView.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/21/26.
//

import SwiftUI
import SwinjectAutoregistration

struct EditAccountView: View {

    private struct OptionalAccount: Equatable {
        let account: Account?
        static let none: OptionalAccount = .init(account: nil)
    }

    @Environment(\.dismiss) private var dismiss

    @State private var screenTitle: String = String(localized: "Add Account")
    @State private var nameString: String = ""
    @State private var nameInstructions: String = ""
    @State private var kind: Account.Kind = .checking
    @State private var trackingMode: Account.TrackingMode = .ledger
    @State private var balance: Money = .zero
    @State private var monthlyPayment: Money = .zero
    @State private var snapshots: [BalanceSnapshot] = []

    @State private var showBalanceEntryView: Bool = false
    @State private var showPaymentEntryView: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    private var accountToEdit: OptionalAccount = .none

    @StateObject var budget: Budget

    init(budget: Budget) {
        self._budget = .init(wrappedValue: budget)
    }

    public func editing(_ account: Account) -> EditAccountView {
        var view = self
        view.accountToEdit = .init(account: account)
        return view
    }

    private var isEditingExisting: Bool { accountToEdit.account != nil }

    private var account: Account? {
        guard let name = Account.Name(nameString) else { return nil }

        // A monthly payment only applies to liabilities, and only when non-zero.
        let payment: Money? = (kind.accountClass == .liability && monthlyPayment.amount > 0)
            ? monthlyPayment
            : nil

        let base = Account(
            id: accountToEdit.account?.id ?? Account.Id(),
            name: name,
            kind: kind,
            trackingMode: trackingMode,
            balance: balance,
            snapshots: snapshots,
            monthlyPayment: payment
        )

        // A new snapshot account records its opening balance; an existing account records a snapshot
        // only when its balance was reconciled here. Editing properties never touches history.
        let shouldRecord = (!isEditingExisting && trackingMode == .snapshot) || didReconcileBalance
        return shouldRecord ? base.recordingSnapshot(value: balance, on: .now) : base
    }

    /// True when editing an existing account whose balance was changed here (a reconcile).
    private var didReconcileBalance: Bool {
        guard let original = accountToEdit.account?.balance else { return false }
        return balance != original
    }

    private var isFormComplete: Bool { account != nil }

    private var balanceLabel: String {
        kind.accountClass == .liability ? String(localized: "Amount Owed") : String(localized: "Balance")
    }

    private func saveAccount() {
        guard let account = account else { return }
        budget.save(account: account)
        dismiss()
    }

    private func deleteAccount() {
        guard let account = accountToEdit.account else { return }
        budget.remove(account: account)
        dismiss()
    }

    private func setNameInstructions(_ nameString: String) {
        withAnimation(.snappy) {
            if nameString.isEmpty { nameInstructions = ""; return }
            if nameString.count > Account.Name.maxTextLength { nameInstructions = "Too long"; return }
            nameInstructions = "\(nameString.count)/\(Account.Name.maxTextLength)"
        }
    }

    private func populateFields(_ account: OptionalAccount) {
        guard let account = account.account else { return }
        guard nameString.isEmpty else { return }

        screenTitle = String(localized: "Edit Account")
        nameString = account.name.value
        kind = account.kind
        trackingMode = account.trackingMode
        balance = account.balance
        monthlyPayment = account.monthlyPayment ?? .zero
        snapshots = account.snapshots
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(spacing: .padding) {
                    Profile()
                    NameField()
                    TypeField()
                    TrackingModeField()
                    if !isEditingExisting {
                        BalanceField()
                    }
                    if kind.accountClass == .liability {
                        MonthlyPaymentField()
                    }
                    if isEditingExisting {
                        DeleteButton()
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .fullScreenCover(isPresented: $showBalanceEntryView) {
            MoneyFieldEntryView(
                title: LocalizedStringKey(balanceLabel),
                money: $balance,
                suggestions: budget.accounts.values.map(\.balance)
            )
        }
        .fullScreenCover(isPresented: $showPaymentEntryView) {
            MoneyFieldEntryView(
                title: "Monthly Payment",
                money: $monthlyPayment,
                suggestions: budget.accounts.values.compactMap(\.monthlyPayment)
            )
        }
        .confirmationDialog(
            "Delete '\(accountToEdit.account?.name.value ?? "")'?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteAccount() }
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: nameString) { _, nameString in setNameInstructions(nameString) }
        .onChange(of: accountToEdit, initial: true) { _, account in populateFields(account) }
        .animation(.snappy, value: kind)
        .animation(.snappy, value: trackingMode)
    }

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text(screenTitle)
                .font(.headline)
                .foregroundStyle(Color.appText)
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.appMutedText)
                Spacer(minLength: 0)
                Button("Save") { saveAccount() }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandTeal)
                    .opacity(isFormComplete ? 1 : .opacityButtonBackground)
                    .disabled(!isFormComplete)
                    .accessibilityIdentifier("EditAccountView.Toolbar.SaveButton")
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    @ViewBuilder private func Profile() -> some View {
        IconCircle(systemName: kind.sfSymbol, size: 64, tint: .brandTeal)
            .frame(maxWidth: .infinity)
            .padding(.top, .paddingSmall)
    }

    @ViewBuilder private func FieldCard<Content: View>(
        _ label: LocalizedStringKey,
        footer: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .kerning(0.5)
                .foregroundStyle(Color.appMutedText)
            content()
            if let footer {
                Text(footer)
                    .font(.caption2)
                    .foregroundStyle(Color.appMutedText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                .foregroundStyle(Color.appSurface)
        }
    }

    @ViewBuilder private func NameField() -> some View {
        FieldCard("Name", footer: nameInstructions.isEmpty ? nil : LocalizedStringKey(nameInstructions)) {
            TextField(
                "Name",
                text: $nameString,
                prompt: Text(Account.Name.sample.value).foregroundStyle(Color.appMutedText)
            )
            .font(.title3)
            .foregroundStyle(Color.appText)
            .tint(Color.brandTeal)
            .autocapitalization(.words)
            .accessibilityIdentifier("EditAccountView.NameField.TextField")
        }
    }

    @ViewBuilder private func TypeField() -> some View {
        FieldCard("Type") {
            Menu {
                Section(Account.Class.asset.pluralName) {
                    ForEach(Account.Kind.kinds(in: .asset), id: \.self) { KindOption($0) }
                }
                Section(Account.Class.liability.pluralName) {
                    ForEach(Account.Kind.kinds(in: .liability), id: \.self) { KindOption($0) }
                }
            } label: {
                MenuLabel(systemName: kind.sfSymbol, text: kind.name)
            }
            .accessibilityIdentifier("EditAccountView.KindField.Menu")
        }
    }

    @ViewBuilder private func KindOption(_ option: Account.Kind) -> some View {
        Button {
            kind = option
        } label: {
            HStack {
                Image(systemName: option.sfSymbol)
                Text(option.name)
                if kind == option { Image(systemName: "checkmark") }
            }
        }
    }

    @ViewBuilder private func TrackingModeField() -> some View {
        FieldCard("Track by", footer: LocalizedStringKey(trackingMode.description)) {
            Menu {
                ForEach(Account.TrackingMode.allCases, id: \.self) { option in
                    Button {
                        trackingMode = option
                    } label: {
                        HStack {
                            Text(option.name)
                            if trackingMode == option { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                MenuLabel(systemName: trackingMode == .ledger ? "list.bullet" : "square.and.pencil", text: trackingMode.name)
            }
            .accessibilityIdentifier("EditAccountView.TrackingModeField.Menu")
        }
    }

    @ViewBuilder private func BalanceField() -> some View {
        FieldCard(LocalizedStringKey(balanceLabel)) {
            Button {
                showBalanceEntryView = true
            } label: {
                ValueLabel(text: balance.formatted())
            }
            .accessibilityIdentifier("EditAccountView.BalanceField.TextField")
        }
    }

    @ViewBuilder private func MonthlyPaymentField() -> some View {
        FieldCard("Monthly Payment", footer: "What you pay toward this each month. Leave at $0.00 if there's no set payment.") {
            Button {
                showPaymentEntryView = true
            } label: {
                ValueLabel(text: monthlyPayment.formatted())
            }
            .accessibilityIdentifier("EditAccountView.MonthlyPaymentField.TextField")
        }
    }

    @ViewBuilder private func MenuLabel(systemName: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemName)
                .foregroundStyle(Color.brandTeal)
            Text(text)
                .foregroundStyle(Color.appText)
            Spacer(minLength: 0)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .foregroundStyle(Color.appMutedText)
        }
        .font(.body.weight(.semibold))
    }

    @ViewBuilder private func ValueLabel(text: String) -> some View {
        HStack(spacing: 8) {
            Text(text)
                .foregroundStyle(Color.appText)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.appMutedText)
        }
        .font(.body.weight(.semibold))
    }

    @ViewBuilder private func DeleteButton() -> some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: .paddingSmall) {
                Image(systemName: "trash")
                Text("Delete Account")
            }
            .font(.headline)
            .foregroundStyle(Color.negative)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .paddingVerticalButtonMedium)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .foregroundStyle(Color.appSurface)
            }
        }
        .accessibilityIdentifier("EditAccountView.DeleteButton")
        .padding(.top, .paddingSmall)
    }
}

#Preview("New") {
    NavigationStack {
        EditAccountView(budget: .previewSample())
    }
}

#Preview("Edit") {
    NavigationStack {
        EditAccountView(budget: .previewSample(accounts: Account.samples))
            .editing(.sampleCarLoan)
    }
}
