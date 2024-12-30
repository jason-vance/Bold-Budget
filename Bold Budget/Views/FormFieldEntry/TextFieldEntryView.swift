//
//  TextFieldEntryView.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/29/24.
//

import SwiftUI

struct TextFieldEntryView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State var title: LocalizedStringKey
    @State var prompt: String
    @Binding var value: String
    @State var autocapitalization: UITextAutocapitalizationType = .none
    @State var instructionsGenerator: (String) -> String
    
    @State private var entryValue: String = ""
    
    @FocusState private var focusState: Bool
    
    init(
        title: LocalizedStringKey,
        prompt: String,
        value: Binding<String>,
        autoCapitalization: UITextAutocapitalizationType = .none,
        instructionsGenerator: @escaping (String) -> String = { _ in "" }
    ) {
        self.title = title
        self.prompt = prompt
        self._value = value
        self.autocapitalization = autoCapitalization
        self.instructionsGenerator = instructionsGenerator
    }
    
    private var instructions: String { instructionsGenerator(entryValue) }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    HStack {
                        Spacer(minLength: 0)
                        let instructions = instructions
                        Text(instructions.isEmpty ? "Placeholder" : instructions)
                            .font(.caption2)
                            .foregroundStyle(Color.text.opacity(.opacityMutedText))
                            .padding(.horizontal, .paddingHorizontalButtonXSmall)
                            .opacity(instructions.isEmpty ? 0 : .opacityMutedText)
                    }
                    TextField(title,
                              text: $entryValue,
                              prompt: Text(prompt).foregroundStyle(Color.text.opacity(.opacityTextFieldPrompt))
                    )
                    .focused($focusState)
                    .textFieldSmall()
                    .autocapitalization(autocapitalization)
                    .accessibilityIdentifier("TextFieldEntryView.TextField")
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
        .onAppear { entryValue = value }
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
            value = entryValue
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
    StatefulPreviewContainer("") { value in
        TextFieldEntryView(
            title: "Title",
            prompt: "Milk Tea, Movie Tickets, etc...",
            value: value
        )
    }
}
