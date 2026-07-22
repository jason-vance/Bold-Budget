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
    @State private var suggestions: [String]
    @State private var autocapitalization: UITextAutocapitalizationType
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
    
    private func normalized(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .components(separatedBy: .init(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789").inverted)
            .joined()
    }

    private var filteredSuggestions: [String] {
        let query = normalized(entryValue)
        return suggestions
            .filter { entryValue.isEmpty || normalized($0).contains(query) }
            .sorted { $0 < $1 }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(alignment: .leading, spacing: .paddingSmall) {
                    TextField(title,
                              text: $entryValue,
                              prompt: Text(prompt).foregroundStyle(Color.appMutedText)
                    )
                    .focused($focusState)
                    .font(.title3)
                    .foregroundStyle(Color.appText)
                    .tint(Color.brandTeal)
                    .autocapitalization(autocapitalization)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                            .foregroundStyle(Color.appSurface)
                    }
                    .accessibilityIdentifier("TextFieldEntryView.TextField")
                    let instructions = instructions
                    if !instructions.isEmpty {
                        Text(instructions)
                            .font(.caption2)
                            .foregroundStyle(Color.appMutedText)
                            .padding(.horizontal, .paddingHorizontalButtonXSmall)
                    }
                    Suggestions()
                        .animation(.snappy, value: entryValue)
                        .padding(.top)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear { focusState = true }
        .onAppear { entryValue = value }
    }

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.appText)
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.appMutedText)
                    .accessibilityIdentifier("TextFieldEntryView.CancelButton")
                Spacer(minLength: 0)
                Button("Save") {
                    value = entryValue
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundStyle(Color.brandTeal)
                .accessibilityIdentifier("TextFieldEntryView.Toolbar.DoneButton")
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    @ViewBuilder private func Suggestions() -> some View {
        if !filteredSuggestions.isEmpty {
            FlowLayout(
                mode: .scrollable,
                items: filteredSuggestions,
                itemSpacing: .paddingCircleButtonSmall
            ) { suggestion in
                Suggestion(suggestion)
            }
        }
    }

    @ViewBuilder private func Suggestion(_ text: String) -> some View {
        Button {
            value = text
            dismiss()
        } label: {
            Text(text).redesignPill()
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
