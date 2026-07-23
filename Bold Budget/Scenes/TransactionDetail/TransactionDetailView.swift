//
//  TransactionDetailView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/6/24.
//

import SwiftUI
import SwiftUIFlowLayout
import SwinjectAutoregistration

/// Read-focused transaction screen in the redesign palette: a self-contained header (back button +
/// overflow menu), a centered hero (icon, amount, category, kind/route, date), an optional ad card,
/// a properties card (title / location / tags), and a total card. Self-contained (own header + scroll)
/// so it carries the redesign look without the shared List chrome, mirroring `AccountDetailView`.
struct TransactionDetailView: View {

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    @StateObject var budget: Budget
    @State var transaction: Transaction
    var category: Transaction.Category { budget.getCategoryBy(id: transaction.categoryId) }

    private var headerAmountColor: Color {
        if transaction.isTransfer { return Color.appMutedText }
        return transaction.kind == .income ? Color.positive : Color.appText
    }

    @State private var subscriptionLevel: SubscriptionLevel? = nil
    @State private var showDeleteDialog: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private let subscriptionManager: SubscriptionLevelProvider

    init(
        budget: Budget,
        transaction: Transaction
    ) {
        self.init(
            budget: budget,
            transaction: transaction,
            subscriptionManager: iocContainer~>SubscriptionLevelProvider.self
        )
    }

    init(
        budget: Budget,
        transaction: Transaction,
        subscriptionManager: SubscriptionLevelProvider
    ) {
        self._budget = .init(wrappedValue: budget)
        self._transaction = .init(initialValue: transaction)
        self.subscriptionManager = subscriptionManager
    }

    private func deleteTransaction() {
        budget.remove(transaction: transaction)
        dismiss()
    }

    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }

    private var hasProperties: Bool {
        transaction.title != nil || transaction.location != nil || !transaction.tags.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(spacing: .padding) {
                    AdCard()
                    Hero()
                    PropertiesCard()
                    TotalCard()
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .alert(alertMessage, isPresented: $showAlert) {}
        .onReceive(subscriptionManager.subscriptionLevelPublisher) { subscriptionLevel = $0 }
        .confirmationDialog(
            "Are you sure you want to delete this transaction?",
            isPresented: $showDeleteDialog,
            titleVisibility: .visible
        ) {
            ConfirmDeleteTransactionButton()
            CancelDeleteTransactionButton()
        }
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            HStack {
                CloseButton()
                Spacer(minLength: 0)
                ToolbarMenu()
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    @ViewBuilder private func CloseButton() -> some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: 2) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .foregroundStyle(Color.appMutedText)
        }
        .accessibilityIdentifier("TransactionDetailView.Toolbar.DismissButton")
    }

    @ViewBuilder private func ToolbarMenu() -> some View {
        Menu {
            EditButton()
            DeleteButton()
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.appMutedText)
        }
    }

    @ViewBuilder private func EditButton() -> some View {
        NavigationLink {
            EditTransactionView(budget: budget)
                .editing(transaction)
                .onTransactionSaved { transaction in
                    self.transaction = transaction
                }
        } label: {
            Label("Edit", systemImage: "pencil")
        }
    }

    @ViewBuilder private func DeleteButton() -> some View {
        Button(role: .destructive) {
            showDeleteDialog = true
        } label: {
            Label("Delete", systemImage: "trash.fill")
        }
    }

    @ViewBuilder private func ConfirmDeleteTransactionButton() -> some View {
        Button(role: .destructive) {
            deleteTransaction()
        } label: {
            Text("Delete")
        }
    }

    @ViewBuilder private func CancelDeleteTransactionButton() -> some View {
        Button(role: .cancel) {
        } label: {
            Text("Cancel")
        }
    }

    // MARK: - Ad

    @ViewBuilder private func AdCard() -> some View {
        if subscriptionLevel == SubscriptionLevel.none {
            NativeAdListRow(ad: $ad, size: .small)
                .frame(maxWidth: .infinity)
                .card()
        }
    }

    // MARK: - Hero

    @ViewBuilder private func Hero() -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(
                systemName: transaction.isTransfer ? "arrow.left.arrow.right" : category.sfSymbol.value,
                size: 64,
                tint: .brandTeal
            )
            Text(transaction.amount.formatted())
                .font(.system(size: 44, weight: .heavy))
                .foregroundStyle(headerAmountColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(transaction.isTransfer ? String(localized: "Transfer") : category.name.value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.appText)
                .multilineTextAlignment(.center)
            Text(transaction.isTransfer
                 ? (budget.transferRouteDescription(for: transaction) ?? Transaction.Kind.transfer.name)
                 : transaction.kind.name)
                .font(.subheadline)
                .foregroundStyle(Color.appMutedText)
                .multilineTextAlignment(.center)
            Text(transaction.date.toDate()!.toBasicUiString())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appMutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, .paddingSmall)
    }

    // MARK: - Properties

    @ViewBuilder private func PropertiesCard() -> some View {
        if hasProperties {
            VStack(spacing: 0) {
                TitleRow()
                LocationRow()
                TagsRow()
            }
            .card(0)
        }
    }

    @ViewBuilder private func RowLabel(_ label: String) -> some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .textCase(.uppercase)
            .kerning(0.5)
            .foregroundStyle(Color.appMutedText)
            .lineLimit(1)
    }

    @ViewBuilder private func LongerTextRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: .paddingSmall) {
            RowLabel(label)
            Text(value)
                .font(.body)
                .foregroundStyle(Color.appText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.padding)
    }

    @ViewBuilder private func TitleRow() -> some View {
        if let title = transaction.title {
            LongerTextRow(label: String(localized: "Title"), value: title.value)
        }
    }

    @ViewBuilder private func LocationRow() -> some View {
        if let location = transaction.location {
            if transaction.title != nil { RowDivider() }
            LongerTextRow(label: String(localized: "Location"), value: location.value)
        }
    }

    @ViewBuilder private func TagsRow() -> some View {
        if !transaction.tags.isEmpty {
            if transaction.title != nil || transaction.location != nil { RowDivider() }
            VStack(alignment: .leading, spacing: .paddingSmall) {
                RowLabel(String(localized: "Tags"))
                FlowLayout(
                    mode: .vstack,
                    items: transaction.tags.sorted { $0.value < $1.value },
                    itemSpacing: .paddingSmall
                ) { tag in
                    Chip(text: tag.value, systemName: "tag", tint: .brandTeal)
                }
            }
            .padding(.padding)
        }
    }

    @ViewBuilder private func RowDivider(opacity: Double = 0.15) -> some View {
        Rectangle()
            .fill(Color.appMutedText.opacity(opacity))
            .frame(height: 1)
            .padding(.leading, .padding)
    }

    // MARK: - Total

    @ViewBuilder private func TotalCard() -> some View {
        HStack {
            Text("Total")
                .font(.callout.weight(.bold))
                .foregroundStyle(Color.appMutedText)
            Spacer(minLength: .padding)
            Text(transaction.amount.formatted())
                .font(.body.weight(.bold))
                .foregroundStyle(Color.appText)
        }
        .card()
    }
}

#Preview {
    NavigationStack {
        TransactionDetailView(
            budget: Budget(info: .sample),
            transaction: .sampleRandomBasic,
            subscriptionManager: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}
