//
//  TextFieldEntryView.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/29/24.
//

import SwiftUI
import SwiftUIFlowLayout

struct TextFieldEntryView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: LocalizedStringKey
    @State private var prompt: String
    @Binding private var value: String
    @State private var suggestions: [String] = []
    @State private var autocapitalization: UITextAutocapitalizationType = .none
    @State private var instructionsGenerator: (String) -> String
    
    @State private var entryValue: String = ""
    
    @FocusState private var focusState: Bool
    
    init(
        title: LocalizedStringKey,
        prompt: String,
        value: Binding<String>,
        suggestions: [String] = [],
        autoCapitalization: UITextAutocapitalizationType = .none,
        instructionsGenerator: @escaping (String) -> String = { _ in "" }
    ) {
        self.title = title
        self.prompt = prompt
        self._value = value
        self.suggestions = suggestions
        self.autocapitalization = autoCapitalization
        self.instructionsGenerator = instructionsGenerator
    }
    
    private var instructions: String { instructionsGenerator(entryValue) }
    
    private var filteredSuggestions: [String] {
        suggestions
            .filter { entryValue.isEmpty || $0.contains(entryValue) }
            .sorted { $0 < $1 }
    }
    
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
                    Suggestions()
                        .animation(.snappy, value: entryValue)
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
    
    @ViewBuilder private func Suggestion(_ text: String) -> some View {
        Button {
            value = text
            dismiss()
        } label: {
            Text(text)
                .buttonLabelSmall()
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
