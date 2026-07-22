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

    @FocusState private var focused: Bool

    init(
        tags: Binding<Set<Transaction.Tag>>,
        budget: Budget
    ) {
        self._tags = tags
        self.budget = budget
    }

    private var sortedEntryTags: [Transaction.Tag] {
        entryTags.sorted { $0.value < $1.value }
    }

    private var suggestedTags: [Transaction.Tag] {
        budget.transactionTags
            .subtracting(entryTags)
            .filter { newTagString.isEmpty || $0.value.lowercased().contains(newTagString.lowercased()) }
            .sorted { $0.value < $1.value }
    }

    /// Selected tags first, then matching suggestions — one flowing list of toggleable chips.
    private var allTags: [Transaction.Tag] {
        sortedEntryTags + suggestedTags
    }

    private var newTag: Transaction.Tag? {
        guard let tag = Transaction.Tag(newTagString) else { return nil }
        return entryTags.contains(tag) ? nil : tag
    }

    private func saveNewTag() {
        guard let tag = newTag else { return }
        entryTags.insert(tag)
        newTagString = ""
    }

    private func add(tag: Transaction.Tag) { entryTags.insert(tag) }
    private func remove(tag: Transaction.Tag) { entryTags.remove(tag) }

    var body: some View {
        VStack(spacing: 0) {
            Header()
            VStack(alignment: .leading, spacing: .padding) {
                NewTagField()
                ScrollView {
                    TagFlow()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .padding()
        }
        .animation(.snappy, value: entryTags)
        .animation(.snappy, value: newTagString)
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear {
            entryTags = tags
            focused = true
        }
    }

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text("Tags")
                .font(.headline)
                .foregroundStyle(Color.appText)
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.appMutedText)
                    .accessibilityIdentifier("TagsEditorView.CancelButton")
                Spacer(minLength: 0)
                Button("Save") {
                    tags = entryTags
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundStyle(Color.brandTeal)
                .accessibilityIdentifier("TagsEditorView.DoneButton")
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    @ViewBuilder private func NewTagField() -> some View {
        HStack(spacing: .paddingSmall) {
            TextField(
                "Add a tag",
                text: $newTagString,
                prompt: Text(Transaction.Tag.sample.value).foregroundStyle(Color.appMutedText)
            )
            .focused($focused)
            .foregroundStyle(Color.appText)
            .tint(Color.brandTeal)
            .textInputAutocapitalization(.words)
            .submitLabel(.done)
            .onSubmit { saveNewTag() }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .foregroundStyle(Color.appSurface)
            }
            .accessibilityIdentifier("TagsEditorView.NewTagField")

            if newTag != nil {
                Button {
                    saveNewTag()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundStyle(Color.appBackground)
                        .frame(width: 48, height: 48)
                        .background { Circle().foregroundStyle(Color.brandTeal) }
                }
                .accessibilityIdentifier("EditTransactionView.TagsField.SaveNewTagButton")
            }
        }
    }

    @ViewBuilder private func TagFlow() -> some View {
        if allTags.isEmpty {
            Text("No tags yet — type above to add one.")
                .font(.subheadline)
                .foregroundStyle(Color.appMutedText)
                .padding(.vertical, .paddingSmall)
        } else {
            FlowLayout(
                mode: .scrollable,
                items: allTags,
                itemSpacing: .paddingSmall
            ) { tag in
                TagChip(tag, selected: entryTags.contains(tag))
            }
        }
    }

    @ViewBuilder private func TagChip(_ tag: Transaction.Tag, selected: Bool) -> some View {
        Button {
            selected ? remove(tag: tag) : add(tag: tag)
        } label: {
            HStack(spacing: 4) {
                Text(tag.value)
                Image(systemName: selected ? "xmark" : "plus")
                    .font(.caption2.weight(.semibold))
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(selected ? Color.appBackground : Color.appText)
            .padding(.horizontal, .paddingHorizontalButtonSmall)
            .padding(.vertical, .paddingVerticalButtonSmall)
            .background {
                Capsule().foregroundStyle(selected ? Color.brandTeal : Color.appSurface)
            }
        }
        .buttonStyle(.plain)
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
