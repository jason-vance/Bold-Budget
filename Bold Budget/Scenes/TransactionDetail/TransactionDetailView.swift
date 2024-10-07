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
    }
    
    @ViewBuilder private func TopBar() -> some View {
        ScreenTitleBar(
            primaryContent: { Text("") },
            leadingContent: { CloseButton() },
            trailingContent: { ZStack {} }
        )
    }
    
    @ViewBuilder private func CloseButton() -> some View {
        Button{
            dismiss()
        } label: {
            TitleBarButtonLabel(sfSymbol: "xmark")
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
            CityAndStateRow()
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
            LongerTextRow(label: String(localized: "Title"), value: title.text)
        }
    }
    
    @ViewBuilder private func CityAndStateRow() -> some View {
        if let cityAndState = transaction.cityAndState {
            LongerTextRow(label: String(localized: "City and State"), value: cityAndState.value)
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
