//
//  AmountFieldEntryView.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/29/24.
//

import SwiftUI

struct AmountFieldEntryView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State var title: LocalizedStringKey
    @Binding var amount: Double
    
    @State private var entryAmount: Double = 0
    
    @FocusState private var focusState: Bool
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    init(
        title: LocalizedStringKey,
        amount: Binding<Double>
    ) {
        self.title = title
        self._amount = amount
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
                              prompt: Text(Money(0)?.formatted() ?? "$0.00")
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($focusState)
                    .textFieldSmall()
                    .accessibilityIdentifier("AmountFieldEntryView.TextField")
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
        .onAppear { entryAmount = amount }
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
            amount = entryAmount
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
}

#Preview {
    StatefulPreviewContainer(Double.zero) { value in
        AmountFieldEntryView(
            title: "Total",
            amount: value
        )
    }
}
