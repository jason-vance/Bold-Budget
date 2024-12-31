//
//  MoneyFieldEntryView.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/29/24.
//

import SwiftUI
import SwiftUIFlowLayout

struct MoneyFieldEntryView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: LocalizedStringKey
    @Binding private var money: Money
    @State private var suggestions: [Money]
    
    @State private var entryAmount: Double = 0
    
    @FocusState private var focusState: Bool
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    init(
        title: LocalizedStringKey,
        money: Binding<Money>,
        suggestions: [Money] = []
    ) {
        self.title = title
        self._money = money
        self.suggestions = suggestions
    }
    
    private var filteredSuggestions: [Money] {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 10 // Set a reasonable maximum
        formatter.minimumFractionDigits = 0 // Don't force decimals if not needed

        guard let entryAmountString = formatter.string(from: NSNumber(value: entryAmount)) else { return [] }
        
        return suggestions
            .filter { entryAmount == 0 || $0.formatted().contains(entryAmountString) }
            .sorted { $0 < $1 }
    }
    
    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    TextField(Money(0)?.formatted() ?? "$0.00",
                              value: $entryAmount,
                              format: .currency(code: "USD"),
                              prompt: Text(Money(0)?.formatted() ?? "$0.00").foregroundStyle(Color.text.opacity(.opacityTextFieldPrompt))
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($focusState)
                    .textFieldSmall()
                    .accessibilityIdentifier("MoneyFieldEntryView.TextField")
                    Suggestions()
                        .animation(.snappy, value: money)
                        .padding(.top)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollContentBackground(.hidden)
            .toolbar { Toolbar() }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(title)
            .navigationBarBackButtonHidden()
            .foregroundStyle(Color.text)
            .background(Color.background)
            .overlay(alignment: .bottomTrailing) { DoneButton().padding() }
        }
        .onAppear { focusState = true }
        .onAppear { entryAmount = money.amount }
        .alert(alertMessage, isPresented: $showAlert) { }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            CancelButton()
        }
    }
    
    @ViewBuilder func CancelButton() -> some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityIdentifier("TextFieldEntryView.CancelButton")
    }
    
    @ViewBuilder func DoneButton() -> some View {
        Button {
            money = Money(entryAmount) ?? money
            dismiss()
        } label: {
            HStack(spacing: 0) {
                Image(systemName: "checkmark")
                Text("DONE")
            }
            .font(.footnote.bold())
            .buttonLabelSmall(isProminent: true)
        }
    }
    
    @ViewBuilder private func Suggestions() -> some View {
        if !filteredSuggestions.isEmpty {
            VStack {
                HStack {
                    Text("Suggestions:")
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                FlowLayout(
                    mode: .scrollable,
                    items: filteredSuggestions,
                    itemSpacing: .paddingCircleButtonSmall
                ) { suggestion in
                    Suggestion(suggestion)
                }
            }
        }
    }
    
    @ViewBuilder private func Suggestion(_ money: Money) -> some View {
        Button {
            self.money = money
            dismiss()
        } label: {
            Text(money.formatted())
                .buttonLabelSmall()
        }
    }
}

#Preview {
    StatefulPreviewContainer(Money.zero) { value in
        MoneyFieldEntryView(
            title: "Total",
            money: value
        )
    }
}
