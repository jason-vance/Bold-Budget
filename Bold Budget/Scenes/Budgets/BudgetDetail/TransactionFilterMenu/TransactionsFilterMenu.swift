//
//  TransactionsFilterMenu.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/5/24.
//

import SwiftUI

struct TransactionsFilter {

    static let none: TransactionsFilter = .init(
        descriptionContainsText: "",
        locationContainsText: "",
        whitelistedCategoryIds: [],
        blacklistedCategoryIds: [],
        whitelistedTags: [],
        blacklistedTags: []
    )

    var descriptionContainsText: String
    var locationContainsText: String
    var whitelistedCategoryIds: Set<Transaction.Category.Id>
    var blacklistedCategoryIds: Set<Transaction.Category.Id>
    var whitelistedTags: Set<Transaction.Tag>
    var blacklistedTags: Set<Transaction.Tag>

    var count: Int {
        var rv: Int = 0

        if !descriptionContainsText.isEmpty { rv += 1 }
        if !locationContainsText.isEmpty { rv += 1 }
        rv += whitelistedCategoryIds.count
        rv += blacklistedCategoryIds.count
        rv += whitelistedTags.count
        rv += blacklistedTags.count

        return rv
    }

    @MainActor func shouldInclude(_ transaction: Transaction, from budget: Budget) -> Bool {
        let descriptionContainsText = descriptionContainsText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !descriptionContainsText.isEmpty, !budget.description(of: transaction).lowercased().contains(descriptionContainsText) {
            return false
        }

        let locationContainsText = locationContainsText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !locationContainsText.isEmpty {
            guard let location = transaction.location, location.value.lowercased().contains(locationContainsText) else {
                return false
            }
        }

        if !whitelistedCategoryIds.isEmpty && !whitelistedCategoryIds.contains(transaction.categoryId) {
            return false
        }

        if blacklistedCategoryIds.contains(transaction.categoryId) {
            return false
        }

        if !whitelistedTags.isEmpty && transaction.tags.intersection(whitelistedTags).isEmpty {
            return false
        }

        if !transaction.tags.intersection(blacklistedTags).isEmpty {
            return false
        }

        return true
    }
}

struct TransactionsFilterMenu: View {

    @StateObject var budget: Budget
    @Binding var isMenuVisible: Bool
    @Binding var transactionsFilter: TransactionsFilter
    @Binding var transactionCount: Int

    @State private var selectedCategoryForWhitelist: Transaction.Category.Id? = nil
    @State private var selectedCategoryForBlacklist: Transaction.Category.Id? = nil

    // Presented as a dropdown under the toolbar (mirroring the timeframe picker): a padded panel
    // anchored at the top that grows/shrinks downward as filters are added, on the redesign palette.
    var body: some View {
        VStack(spacing: .padding) {
            LabeledSection("Description") { DescriptionField() }
            LabeledSection("Location") { LocationField() }
            LabeledSection("Categories") { CategoriesField() }
            LabeledSection("Tags") { TagsField() }
            VStack(spacing: .paddingSmall) {
                SeeTransactionsButton()
                ClearAllButton()
            }
            .padding(.top, .paddingSmall)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .top)
        .foregroundStyle(Color.appText)
        .onChange(of: selectedCategoryForWhitelist) { _, id in
            if let id {
                withAnimation(.snappy) { transactionsFilter.whitelistedCategoryIds.insert(id) }
                selectedCategoryForWhitelist = nil
            }
        }
        .onChange(of: selectedCategoryForBlacklist) { _, id in
            if let id {
                withAnimation(.snappy) { transactionsFilter.blacklistedCategoryIds.insert(id) }
                selectedCategoryForBlacklist = nil
            }
        }
    }

    // MARK: - Section scaffolding

    @ViewBuilder private func LabeledSection<Content: View>(
        _ label: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: .paddingSmall) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .kerning(0.6)
                .foregroundStyle(Color.appMutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
    }

    /// A tappable row that navigates to a picker, styled as a redesign surface pill.
    @ViewBuilder private func EntryRow<Destination: View>(
        _ title: LocalizedStringKey,
        systemName: String,
        tint: Color,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.appText)
                Spacer(minLength: 0)
                Image(systemName: systemName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
            }
            .padding(.horizontal, .padding)
            .padding(.vertical, .paddingVerticalButtonSmall)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                    .foregroundStyle(Color.appSurface)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// A selected filter value, rendered as a removable chip.
    @ViewBuilder private func SelectedChip(tint: Color, remove: @escaping () -> Void, @ViewBuilder label: () -> some View) -> some View {
        HStack(spacing: .paddingSmall) {
            label()
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.appText)
            Spacer(minLength: 0)
            Button {
                withAnimation(.snappy) { remove() }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.appMutedText)
                    .frame(width: 24, height: 24)
                    .background { Circle().foregroundStyle(Color.appText.opacity(.opacityButtonBackground)) }
            }
        }
        .padding(.leading, .padding)
        .padding(.trailing, .paddingCircleButtonSmall)
        .padding(.vertical, .paddingCircleButtonSmall)
        .background {
            RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                .foregroundStyle(tint.opacity(.opacityButtonBackground))
        }
    }

    // MARK: - Categories

    @ViewBuilder private func CategoriesField() -> some View {
        VStack(spacing: .paddingSmall) {
            if transactionsFilter.blacklistedCategoryIds.isEmpty {
                EntryRow("Include Categories", systemName: "folder.badge.plus", tint: .brandTeal) {
                    TransactionCategoryPickerView(budget: budget, selectedCategoryId: $selectedCategoryForWhitelist)
                        .pickerMode(.picker)
                }
                ForEach(sortedCategoryIds(transactionsFilter.whitelistedCategoryIds), id: \.self) { categoryId in
                    CategoryChip(categoryId, tint: .brandTeal) {
                        _ = transactionsFilter.whitelistedCategoryIds.remove(categoryId)
                    }
                }
            }
            if transactionsFilter.whitelistedCategoryIds.isEmpty {
                EntryRow("Exclude Categories", systemName: "folder.badge.minus", tint: .negative) {
                    TransactionCategoryPickerView(budget: budget, selectedCategoryId: $selectedCategoryForBlacklist)
                        .pickerMode(.picker)
                }
                ForEach(sortedCategoryIds(transactionsFilter.blacklistedCategoryIds), id: \.self) { categoryId in
                    CategoryChip(categoryId, tint: .negative) {
                        _ = transactionsFilter.blacklistedCategoryIds.remove(categoryId)
                    }
                }
            }
        }
    }

    private func sortedCategoryIds(_ ids: Set<Transaction.Category.Id>) -> [Transaction.Category.Id] {
        ids.sorted { budget.getCategoryBy(id: $0).name.value < budget.getCategoryBy(id: $1).name.value }
    }

    @ViewBuilder private func CategoryChip(_ categoryId: Transaction.Category.Id, tint: Color, remove: @escaping () -> Void) -> some View {
        let category = budget.getCategoryBy(id: categoryId)
        SelectedChip(tint: tint, remove: remove) {
            HStack(spacing: .paddingSmall) {
                Image(systemName: category.sfSymbol.value)
                    .font(.footnote)
                    .foregroundStyle(tint)
                Text(category.name.value)
            }
        }
    }

    // MARK: - Tags

    @ViewBuilder private func TagsField() -> some View {
        VStack(spacing: .paddingSmall) {
            EntryRow("Include Tags", systemName: "tag", tint: .brandTeal) {
                TransactionTagPickerView(budget: budget) { transactionsFilter.whitelistedTags.insert($0) }
            }
            .accessibilityIdentifier("TransactionsFilterMenu.TagsIncludeFieldButton")
            ForEach(transactionsFilter.whitelistedTags.sorted { $0.value < $1.value }) { tag in
                TagChip(tag, tint: .brandTeal) { _ = transactionsFilter.whitelistedTags.remove(tag) }
            }
            EntryRow("Exclude Tags", systemName: "tag", tint: .negative) {
                TransactionTagPickerView(budget: budget) { transactionsFilter.blacklistedTags.insert($0) }
            }
            .accessibilityIdentifier("TransactionsFilterMenu.TagsExcludeFieldButton")
            ForEach(transactionsFilter.blacklistedTags.sorted { $0.value < $1.value }) { tag in
                TagChip(tag, tint: .negative) { _ = transactionsFilter.blacklistedTags.remove(tag) }
            }
        }
    }

    @ViewBuilder private func TagChip(_ tag: Transaction.Tag, tint: Color, remove: @escaping () -> Void) -> some View {
        SelectedChip(tint: tint, remove: remove) {
            HStack(spacing: .paddingSmall) {
                Image(systemName: "tag")
                    .font(.footnote)
                    .foregroundStyle(tint)
                Text(tag.value)
            }
        }
    }

    // MARK: - Text fields

    @ViewBuilder private func DescriptionField() -> some View {
        FilterTextField(
            text: $transactionsFilter.descriptionContainsText,
            placeholder: "Milk Tea, Movie Tickets, etc..."
        )
    }

    @ViewBuilder private func LocationField() -> some View {
        FilterTextField(
            text: $transactionsFilter.locationContainsText,
            placeholder: "Seattle, WA, etc..."
        )
    }

    @ViewBuilder private func FilterTextField(text: Binding<String>, placeholder: LocalizedStringKey) -> some View {
        HStack(spacing: .paddingSmall) {
            TextField("", text: text, prompt: Text(placeholder).foregroundStyle(Color.appMutedText))
                .tint(Color.brandTeal)
                .foregroundStyle(Color.appText)
            if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.appMutedText)
                        .frame(width: 24, height: 24)
                        .background { Circle().foregroundStyle(Color.appText.opacity(.opacityButtonBackground)) }
                }
            }
        }
        .padding(.leading, .padding)
        .padding(.trailing, .paddingCircleButtonSmall)
        .padding(.vertical, .paddingCircleButtonSmall)
        .background {
            RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                .foregroundStyle(Color.appSurface)
        }
    }

    // MARK: - Actions

    @ViewBuilder private func SeeTransactionsButton() -> some View {
        Button {
            withAnimation(.snappy) { isMenuVisible = false }
        } label: {
            Text("See \(transactionCount) Transactions")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .paddingVerticalButtonMedium)
                .background {
                    RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                        .foregroundStyle(Color.brandTeal)
                }
        }
    }

    @ViewBuilder private func ClearAllButton() -> some View {
        Button {
            withAnimation(.snappy) { self.transactionsFilter = .none }
        } label: {
            Text("Clear Filters")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(transactionsFilter.count > 0 ? Color.appText : Color.appMutedText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .paddingVerticalButtonSmall)
        }
        .disabled(transactionsFilter.count == 0)
    }
}

#Preview {
    NavigationStack {
        StatefulPreviewContainer(TransactionsFilter.none) { filter in
            ScrollView {
                TransactionsFilterMenu(
                    budget: Budget(info: .sample),
                    isMenuVisible: .constant(true),
                    transactionsFilter: filter,
                    transactionCount: .constant(10)
                )
            }
            .background(Color.appBackground)
        }
    }
}
