//
//  TagsEditorView.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/29/24.
//

import SwiftUI
import SwiftUIFlowLayout

struct TagsEditorView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @Binding private var tags: Set<Transaction.Tag>
    @State private var budget: Budget
    
    @State private var newTagString: String = ""
    @State private var entryTags: Set<Transaction.Tag> = []
    
    var sortedEntryTags: [Transaction.Tag] {
        entryTags
            .sorted { $0.value < $1.value }
    }
    
    var suggestedTags: [Transaction.Tag] {
        budget.transactionTags
            .subtracting(entryTags)
            .filter { newTagString.isEmpty || $0.value.lowercased().contains(newTagString.lowercased()) }
            .sorted { $0.value < $1.value }
    }
    
    private var newTagInstructions: String {
        if newTagString.isEmpty { return "" }
        if newTagString.count < Transaction.Tag.minTextLength { return "Too short" }
        if newTagString.count > Transaction.Tag.maxTextLength { return "Too long" }
        return "\(newTagString.count)/\(Transaction.Tag.maxTextLength)"
    }
    
    private func saveNewTag() {
        if let tag = Transaction.Tag(newTagString) {
            entryTags.insert(tag)
            newTagString = ""
        }
    }
    
    private func add(tag: Transaction.Tag) {
        entryTags.insert(tag)
    }
    
    private func remove(tag: Transaction.Tag) {
        entryTags.remove(tag)
    }
    
    init(
        tags: Binding<Set<Transaction.Tag>>,
        budget: Budget
    ) {
        self._tags = tags
        self.budget = budget
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NewTagField()
                    .padding()
                BarDivider()
                ScrollView {
                    VStack {
                        SelectedTags()
                        SuggestedTags()
                    }
                    .padding()
                }
            }
            .animation(.snappy, value: entryTags)
            .toolbar { Toolbar() }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Tags")
            .navigationBarBackButtonHidden()
            .overlay(alignment: .bottomTrailing) { DoneButton().padding() }
            .foregroundStyle(Color.text)
            .background(Color.background)
        }
        .onAppear { entryTags = tags }
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
        .accessibilityIdentifier("TagsEditorView.CancelButton")
    }
    
    @ViewBuilder func DoneButton() -> some View {
        Button {
            tags = entryTags
            dismiss()
        } label: {
            HStack(spacing: 0) {
                Image(systemName: "checkmark")
                Text("DONE")
            }
            .font(.footnote.bold())
            .buttonLabelSmall(isProminent: true)
        }
        .accessibilityIdentifier("TagsEditorView.DoneButton")
    }
    
    @ViewBuilder private func NewTagField() -> some View {
        VStack {
            HStack {
                Text("Search for or add a Tag")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                Text(newTagInstructions)
                    .font(.caption2)
                    .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
            }
            HStack {
                TextField("Search for or add a Tag",
                          text: $newTagString,
                          prompt: Text(Transaction.Tag.sample.value).foregroundStyle(Color.text.opacity(.opacityTextFieldPrompt))
                )
                .textFieldSmall()
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("TagsEditorView.NewTagField")
                SaveNewTagButton()
            }
        }
    }
    
    @ViewBuilder func SaveNewTagButton() -> some View {
        Button {
            saveNewTag()
        } label: {
            Text("Add")
                .buttonLabelMedium()
        }
        .accessibilityIdentifier("EditTransactionView.TagsField.SaveNewTagButton")
    }
    
    @ViewBuilder private func SelectedTags() -> some View {
        VStack {
            HStack {
                Text("Selected Tags:")
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            if entryTags.isEmpty {
                Text("No tags selected")
                    .padding(.paddingCircleButtonMedium)
            } else {
                FlowLayout(
                    mode: .scrollable,
                    items: sortedEntryTags,
                    itemSpacing: .paddingCircleButtonMedium
                ) { item in
                    SelectedTag(item)
                }
            }
        }
    }
    
    @ViewBuilder private func SuggestedTags() -> some View {
        if !suggestedTags.isEmpty {
            VStack {
                HStack {
                    Text("Suggested Tags:")
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                FlowLayout(
                    mode: .scrollable,
                    items: suggestedTags,
                    itemSpacing: .paddingCircleButtonMedium
                ) { item in
                    SuggestionTag(item)
                }
            }
        }
    }
    
    @ViewBuilder func SelectedTag(_ tag: Transaction.Tag) -> some View {
        Button {
            remove(tag: tag)
        } label: {
            HStack(spacing: .paddingCircleButtonSmall) {
                Image(systemName: "checkmark.circle.fill")
                TransactionTagView(tag)
            }
        }
    }
    
    @ViewBuilder func SuggestionTag(_ tag: Transaction.Tag) -> some View {
        Button {
            add(tag: tag)
        } label: {
            HStack(spacing: .paddingCircleButtonSmall) {
                Image(systemName: "circle")
                TransactionTagView(tag)
            }
        }
    }
}

#Preview {
    StatefulPreviewContainer(Set<Transaction.Tag>()) { tags in
        TagsEditorView(
            tags: tags,
            budget: Budget(info: .sample)
        )
    }
}
