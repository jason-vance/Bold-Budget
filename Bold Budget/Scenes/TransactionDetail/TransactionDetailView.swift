//
//  TransactionDetailView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/6/24.
//

import SwiftUI

struct TransactionDetailView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State var transaction: Transaction
    
    @State private var showDeleteDialog: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    private func deleteTransaction() {
        guard let deleter = iocContainer.resolve(TransactionDeleter.self) else {
            show(alert: "Failed to delete. Service unavailable.")
            return
        }
        
        do {
            try deleter.delete(transaction: transaction)
            dismiss()
        } catch {
            show(alert: "Failed to delete the transaction. \(error.localizedDescription)")
        }
    }
    
    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            List {
                HeaderSection()
                PropertiesSection()
                ItemizedSection()
            }
            .scrollDismissesKeyboard(.immediately)
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .background(Color.background)
        .alert(alertMessage, isPresented: $showAlert) {}
    }
    
    @ViewBuilder private func TopBar() -> some View {
        ScreenTitleBar(
            primaryContent: { Text("") },
            leadingContent: { CloseButton() },
            trailingContent: { DeleteButton() }
        )
    }
    
    @ViewBuilder private func CloseButton() -> some View {
        Button{
            dismiss()
        } label: {
            TitleBarButtonLabel(sfSymbol: "xmark")
        }
    }
    
    @ViewBuilder private func DeleteButton() -> some View {
        Button {
            showDeleteDialog = true
        } label: {
            TitleBarButtonLabel(sfSymbol: "trash.fill")
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
                    Image(systemName: transaction.category.sfSymbol.value)
                    Text(transaction.category.name.value)
                    Spacer(minLength: 0)
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.text)
                HStack {
                    Spacer(minLength: 0)
                    Text(transaction.category.kind.name)
                        .font(.body.weight(.light))
                        .foregroundStyle(Color.text)
                        .multilineTextAlignment(.center)
                    Spacer(minLength: 0)
                }
                HStack {
                    Spacer(minLength: 0)
                    Text(transaction.date.toDate()!.toBasicUiString())
                        .font(.caption.bold())
                        .foregroundStyle(Color.text.opacity(0.75))
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
    
    @ViewBuilder private func ShorterTextRow(
        label: String,
        labelFont: Font = .caption.bold(),
        value: String,
        valueFont: Font = .body
    ) -> some View {
        HStack {
            Text(label)
                .font(labelFont)
                .foregroundStyle(Color.text.opacity(0.75))
                .lineLimit(1)
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
                Text(label)
                    .font(.caption.bold())
                    .foregroundStyle(Color.text.opacity(0.75))
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
    TransactionDetailView(transaction: .sampleRandomBasic)
}
