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

    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    @State private var screenTitle: String = String(localized: "Add Account")
    @State private var nameString: String = ""
    @State private var nameInstructions: String = ""
    @State private var kind: Account.Kind = .checking
    @State private var trackingMode: Account.TrackingMode = .ledger
    @State private var balance: Money = .zero
    @State private var monthlyPayment: Money = .zero

    @State private var showBalanceEntryView: Bool = false
    @State private var showPaymentEntryView: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    @State private var subscriptionLevel: SubscriptionLevel = .none
    private let subscriptionLevelProvider: SubscriptionLevelProvider

    private var accountToEdit: OptionalAccount = .none

    @StateObject var budget: Budget

    init(
        budget: Budget
    ) {
        self.init(
            budget: budget,
            subscriptionLevelProvider: iocContainer~>SubscriptionLevelProvider.self
        )
    }

    init(
        budget: Budget,
        subscriptionLevelProvider: SubscriptionLevelProvider
    ) {
        self._budget = .init(wrappedValue: budget)
        self.subscriptionLevelProvider = subscriptionLevelProvider
    }

    public func editing(_ account: Account) -> EditAccountView {
        var view = self
        view.accountToEdit = .init(account: account)
        return view
    }

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
            snapshots: accountToEdit.account?.snapshots ?? [],
            monthlyPayment: payment
        )

        // Snapshot accounts record the entered balance as this month's data point.
        return trackingMode == .snapshot
            ? base.recordingSnapshot(value: balance, on: .now)
            : base
    }

    private var isFormComplete: Bool { account != nil }

    private var balanceLabel: String {
        kind.accountClass == .liability
            ? String(localized: "Amount Owed")
            : String(localized: "Balance")
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
        let isFormEmpty = nameString.isEmpty
        guard isFormEmpty else { return }

        screenTitle = String(localized: "Edit Account")
        nameString = account.name.value
        kind = account.kind
        trackingMode = account.trackingMode
        balance = account.balance
        monthlyPayment = account.monthlyPayment ?? .zero
    }

    var body: some View {
        Form {
            AdSection()
            Section {
                NameField()
                KindField()
            } header: {
                Text("")
                    .foregroundStyle(Color.text)
            }
            Section {
                BalanceField()
                TrackingModeField()
            } header: {
                Text(balanceLabel)
                    .foregroundStyle(Color.text)
            } footer: {
                Text(trackingMode.description)
                    .foregroundStyle(Color.text.opacity(.opacityMutedText))
            }
            MonthlyPaymentSection()
            BalanceHistorySection()
            DeleteSection()
        }
        .scrollDismissesKeyboard(.immediately)
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .toolbar { Toolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(screenTitle)
        .foregroundStyle(Color.text)
        .background(Color.background.ignoresSafeArea())
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .confirmationDialog(
            "Delete '\(accountToEdit.account?.name.value ?? "")'?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: nameString) { _, nameString in setNameInstructions(nameString) }
        .onChange(of: accountToEdit, initial: true) { _, account in populateFields(account) }
        .onReceive(subscriptionLevelProvider.subscriptionLevelPublisher) { subscriptionLevel = $0 }
        .animation(.snappy, value: kind)
        .animation(.snappy, value: trackingMode)
    }

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            SaveButton()
        }
    }

    @ViewBuilder private func SaveButton() -> some View {
        Button {
            saveAccount()
        } label: {
            Image(systemName: "checkmark")
        }
        .opacity(isFormComplete ? 1 : .opacityButtonBackground)
        .disabled(!isFormComplete)
        .accessibilityIdentifier("EditAccountView.Toolbar.SaveButton")
    }

    @ViewBuilder private func AdSection() -> some View {
        if subscriptionLevel == SubscriptionLevel.none {
            Section {
                NativeAdListRow(ad: $ad, size: .small)
                    .listRow()
            }
        }
    }

    @ViewBuilder private func NameField() -> some View {
        VStack {
            HStack {
                Text("Name")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
            }
            TextField("Name",
                      text: $nameString,
                      prompt: Text(Account.Name.sample.value).foregroundStyle(Color.text.opacity(.opacityTextFieldPrompt))
            )
            .textFieldSmall()
            .autocapitalization(.words)
            .accessibilityIdentifier("EditAccountView.NameField.TextField")
            HStack {
                Spacer(minLength: 0)
                Text(nameInstructions)
                    .font(.caption2)
                    .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
            }
        }
        .listRow()
    }

    @ViewBuilder private func KindField() -> some View {
        HStack {
            Text("Type")
                .foregroundStyle(Color.text)
            Spacer(minLength: 0)
            Menu {
                Section(Account.Class.asset.pluralName) {
                    ForEach(Account.Kind.kinds(in: .asset), id: \.self) { option in
                        KindOption(option)
                    }
                }
                Section(Account.Class.liability.pluralName) {
                    ForEach(Account.Kind.kinds(in: .liability), id: \.self) { option in
                        KindOption(option)
                    }
                }
            } label: {
                HStack(spacing: .paddingSmall) {
                    Image(systemName: kind.sfSymbol)
                    Text(kind.name)
                }
                .buttonLabelSmall()
            }
            .accessibilityIdentifier("EditAccountView.KindField.Menu")
        }
        .listRow()
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

    @ViewBuilder private func BalanceField() -> some View {
        HStack {
            Text(balanceLabel)
                .foregroundStyle(Color.text)
            Spacer(minLength: 0)
            Button {
                showBalanceEntryView = true
            } label: {
                HStack {
                    Spacer(minLength: 0)
                    Text(balance.formatted())
                        .multilineTextAlignment(.trailing)
                }
            }
            .frame(width: 160)
            .textFieldSmall()
            .accessibilityIdentifier("EditAccountView.BalanceField.TextField")
        }
        .listRow()
        .fullScreenCover(isPresented: $showBalanceEntryView) {
            MoneyFieldEntryView(
                title: LocalizedStringKey(balanceLabel),
                money: $balance,
                suggestions: budget.accounts.values.map(\.balance)
            )
        }
    }

    @ViewBuilder private func TrackingModeField() -> some View {
        HStack {
            Text("Track by")
                .foregroundStyle(Color.text)
            Spacer(minLength: 0)
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
                Text(trackingMode.name)
                    .buttonLabelSmall()
            }
            .accessibilityIdentifier("EditAccountView.TrackingModeField.Menu")
        }
        .listRow()
    }

    @ViewBuilder private func MonthlyPaymentSection() -> some View {
        if kind.accountClass == .liability {
            Section {
                HStack {
                    Text("Monthly Payment")
                        .foregroundStyle(Color.text)
                    Spacer(minLength: 0)
                    Button {
                        showPaymentEntryView = true
                    } label: {
                        HStack {
                            Spacer(minLength: 0)
                            Text(monthlyPayment.formatted())
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .frame(width: 160)
                    .textFieldSmall()
                    .accessibilityIdentifier("EditAccountView.MonthlyPaymentField.TextField")
                }
                .listRow()
                .fullScreenCover(isPresented: $showPaymentEntryView) {
                    MoneyFieldEntryView(
                        title: "Monthly Payment",
                        money: $monthlyPayment,
                        suggestions: budget.accounts.values.compactMap(\.monthlyPayment)
                    )
                }
            } header: {
                Text("Monthly Payment")
                    .foregroundStyle(Color.text)
            } footer: {
                Text("What you pay toward this each month. Leave at $0.00 if there's no set payment.")
                    .foregroundStyle(Color.text.opacity(.opacityMutedText))
            }
        }
    }

    @ViewBuilder private func BalanceHistorySection() -> some View {
        let snapshots = accountToEdit.account?.snapshots ?? []
        if trackingMode == .snapshot, !snapshots.isEmpty {
            Section {
                ForEach(snapshots) { snapshot in
                    HStack {
                        Text(snapshot.date.toDate()?.toBasicUiString() ?? "—")
                            .foregroundStyle(Color.text)
                        Spacer(minLength: 0)
                        Text(snapshot.value.formatted())
                            .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    }
                    .listRow()
                }
            } header: {
                Text("Balance History")
                    .foregroundStyle(Color.text)
            }
        }
    }

    @ViewBuilder private func DeleteSection() -> some View {
        if accountToEdit.account != nil {
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Account")
                        Spacer(minLength: 0)
                    }
                }
                .listRow()
                .accessibilityIdentifier("EditAccountView.DeleteButton")
            }
        }
    }
}

#Preview("New") {
    NavigationStack {
        EditAccountView(
            budget: .previewSample(),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}

#Preview("Edit Snapshot Account") {
    NavigationStack {
        EditAccountView(
            budget: .previewSample(accounts: Account.samples),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
        .editing(.sampleRobinhood)
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}
