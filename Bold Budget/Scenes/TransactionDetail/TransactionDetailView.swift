//
//  TransactionDetailView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/6/24.
//

import SwiftUI
import SwinjectAutoregistration

struct TransactionDetailView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var budget: Budget
    @State var transaction: Transaction
    var category: Transaction.Category { budget.getCategoryBy(id: transaction.categoryId) }
    
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
    
    var body: some View {
        List {
            AdSection()
            HeaderSection()
            PropertiesSection()
            ItemizedSection()
        }
        .scrollDismissesKeyboard(.immediately)
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .toolbar { Toolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .foregroundStyle(Color.text)
        .background(Color.background)
        .alert(alertMessage, isPresented: $showAlert) {}
        .onReceive(subscriptionManager.subscriptionLevelPublisher) { subscriptionLevel = $0 }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            CloseButton()
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            ToolbarMenu()
        }
    }
    
    @ViewBuilder private func CloseButton() -> some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.backward")
        }
        .accessibilityIdentifier("TransactionDetailView.Toolbar.DismissButton")
    }
    
    @ViewBuilder private func ToolbarMenu() -> some View {
        Menu {
            EditButton()
            DeleteButton()
        } label: {
            Image(systemName: "ellipsis")
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
        Button {
            showDeleteDialog = true
        } label: {
            Label("Delete", systemImage: "trash.fill")
        }
        .confirmationDialog(
            "Are you sure you want to delete this transaction?",
            isPresented: $showDeleteDialog,
            titleVisibility: .visible
        ) {
            ConfirmDeleteTransactionButton()
            CancelDeleteTransactionButton()
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
    
    @ViewBuilder func AdSection() -> some View {
        if subscriptionLevel == SubscriptionLevel.none {
            Section {
                SimpleBannerAdView()
            }
        }
    }
    
    @ViewBuilder private func HeaderSection() -> some View {
        Section {
            VStack {
                HStack {
                    Spacer(minLength: 0)
                    Text(transaction.amount.formatted())
                        .minimumScaleFactor(0.5)
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.text)
                    Spacer(minLength: 0)
                }
                HStack {
                    Spacer(minLength: 0)
                    Image(systemName: category.sfSymbol.value)
                    Text(category.name.value)
                    Spacer(minLength: 0)
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.text)
                HStack {
                    Spacer(minLength: 0)
                    Text(category.kind.name)
                        .font(.body.weight(.light))
                        .foregroundStyle(Color.text)
                        .multilineTextAlignment(.center)
                    Spacer(minLength: 0)
                }
                HStack {
                    Spacer(minLength: 0)
                    Text(transaction.date.toDate()!.toBasicUiString())
                        .font(.caption.bold())
                        .foregroundStyle(Color.text.opacity(.opacityMutedText))
                        .multilineTextAlignment(.center)
                    Spacer(minLength: 0)
                }
            }
            .listRowBackground(Color.background)
            .listRowSeparator(.hidden)
        } header: {
            ZStack {}
        }
    }
    
    @ViewBuilder private func PropertiesSection() -> some View {
        Section {
            TitleRow()
            LocationRow()
            TagsRow()
        } header: {
            ZStack {}
        }
    }
    
    @ViewBuilder private func ItemizedSection() -> some View {
        Section {
            TotalRow()
        } header: {
            ZStack {}
        }
    }
    
    @ViewBuilder private func RowLabel(_ label: String, labelFont: Font = .caption.bold()) -> some View {
        Text(label)
            .font(labelFont)
            .foregroundStyle(Color.text.opacity(.opacityMutedText))
            .lineLimit(1)
    }
    
    @ViewBuilder private func ShorterTextRow(
        label: String,
        labelFont: Font = .caption.bold(),
        value: String,
        valueFont: Font = .body
    ) -> some View {
        HStack {
            RowLabel(label, labelFont: labelFont)
            Spacer(minLength: .padding)
            Text(value)
                .font(valueFont)
                .foregroundStyle(Color.text)
        }
        .transactionPropertyRow()
    }
    
    @ViewBuilder private func LongerTextRow(label: String, value: String) -> some View {
        VStack {
            HStack {
                RowLabel(label)
                Spacer(minLength: 0)
            }
            HStack {
                Text(value)
                    .font(.body)
                    .foregroundStyle(Color.text)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
        }
        .transactionPropertyRow()
    }
    
    @ViewBuilder private func TitleRow() -> some View {
        if let title = transaction.title {
            LongerTextRow(label: String(localized: "Title"), value: title.value)
        }
    }
    
    @ViewBuilder private func LocationRow() -> some View {
        if let location = transaction.location {
            LongerTextRow(label: String(localized: "Location"), value: location.value)
        }
    }
    
    @ViewBuilder private func TagsRow() -> some View {
        if !transaction.tags.isEmpty {
            VStack(alignment: .leading, spacing: .padding) {
                HStack {
                    RowLabel(String(localized: "Tags"))
                    Spacer(minLength: 0)
                }
                ForEach(transaction.tags.sorted { $0.value < $1.value }) { tag in
                    TransactionTagView(tag)
                }
            }
            .transactionPropertyRow()
        }
    }
    
    @ViewBuilder private func TotalRow() -> some View {
        ShorterTextRow(
            label: String(localized: "Total"),
            labelFont: .callout.bold(),
            value: transaction.amount.formatted(),
            valueFont: .body.bold()
        )
    }
}

#Preview {
    NavigationStack {
        TransactionDetailView(
            budget: Budget(info: .sample),
            transaction: .sampleRandomBasic
        )
    }
}
