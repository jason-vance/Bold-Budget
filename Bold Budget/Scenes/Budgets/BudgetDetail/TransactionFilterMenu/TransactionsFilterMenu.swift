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

    var body: some View {
        VStack {
            Form {
                Section {
                    ContainsAnyTextField()
                    LocationField()
                    if transactionsFilter.blacklistedCategoryIds.isEmpty {
                        CategoryIncludeField()
                    }
                    if transactionsFilter.whitelistedCategoryIds.isEmpty {
                        CategoryExcludeField()
                    }
                    TagsIncludeField()
                    TagsExcludeField()
                } header: {
                    Text("Filter Transactions")
                        .foregroundStyle(Color.text)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            SeeTransactionsButton()
                .padding(.horizontal)
            ClearAllButton()
                .padding(.horizontal)
        }
        .padding(.bottom)
        .foregroundStyle(Color.text)
        .background(Color.background.ignoresSafeArea(.keyboard))
        .onChange(of: selectedCategoryForWhitelist) { _, id in
            if let id {
                transactionsFilter.whitelistedCategoryIds.insert(id)
                selectedCategoryForWhitelist = nil
            }
        }
        .onChange(of: selectedCategoryForBlacklist) { _, id in
            if let id {
                transactionsFilter.blacklistedCategoryIds.insert(id)
                selectedCategoryForBlacklist = nil
            }
        }
    }

    @ViewBuilder private func CategoryIncludeField() -> some View {
        NavigationLink {
            TransactionCategoryPickerView(
                budget: budget,
                selectedCategoryId: $selectedCategoryForWhitelist
            )
            .pickerMode(.picker)
        } label: {
            HStack {
                Text("Include Categories")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                AddCategoryButtonLabel(isInclude: true)
            }
        }
        .listRow()
        let sortedWhitelistedIds = transactionsFilter.whitelistedCategoryIds.sorted {
            budget.getCategoryBy(id: $0).name.value < budget.getCategoryBy(id: $1).name.value
        }
        ForEach(sortedWhitelistedIds, id: \.self) { categoryId in
            let category = budget.getCategoryBy(id: categoryId)
            HStack {
                Button {
                    withAnimation(.snappy) { _ = transactionsFilter.whitelistedCategoryIds.remove(categoryId) }
                } label: {
                    Image(systemName: "xmark")
                        .buttonSymbolCircleSmall()
                }
                Image(systemName: category.sfSymbol.value)
                Text(category.name.value)
                    .buttonLabelSmall()
                Spacer(minLength: 0)
            }
            .listRow()
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder private func CategoryExcludeField() -> some View {
        NavigationLink {
            TransactionCategoryPickerView(
                budget: budget,
                selectedCategoryId: $selectedCategoryForBlacklist
            )
            .pickerMode(.picker)
        } label: {
            HStack {
                Text("Exclude Categories")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                AddCategoryButtonLabel(isInclude: false)
            }
        }
        .listRow()
        let sortedBlacklistedIds = transactionsFilter.blacklistedCategoryIds.sorted {
            budget.getCategoryBy(id: $0).name.value < budget.getCategoryBy(id: $1).name.value
        }
        ForEach(sortedBlacklistedIds, id: \.self) { categoryId in
            let category = budget.getCategoryBy(id: categoryId)
            HStack {
                Button {
                    withAnimation(.snappy) { _ = transactionsFilter.blacklistedCategoryIds.remove(categoryId) }
                } label: {
                    Image(systemName: "xmark")
                        .buttonSymbolCircleSmall()
                }
                Image(systemName: category.sfSymbol.value)
                Text(category.name.value)
                    .buttonLabelSmall()
                Spacer(minLength: 0)
            }
            .listRow()
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder private func AddCategoryButtonLabel(isInclude: Bool) -> some View {
        Image(systemName: isInclude ? "folder.badge.plus" : "folder.badge.minus")
            .buttonLabelSmall()
    }

    @ViewBuilder private func TagsIncludeField() -> some View {
        NavigationLink {
            TransactionTagPickerView(budget: budget) { transactionsFilter.whitelistedTags.insert($0) }
        } label: {
            HStack {
                Text("Include Tags")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                AddTagButtonLabel(isInclude: true)
            }
        }
        .listRow()
        .accessibilityIdentifier("TransactionsFilterMenu.TagsIncludeFieldButton")
        if !transactionsFilter.whitelistedTags.isEmpty {
            ForEach(transactionsFilter.whitelistedTags.sorted { $0.value < $1.value }) { tag in
                HStack {
                    Button {
                        withAnimation(.snappy) { _ = transactionsFilter.whitelistedTags.remove(tag) }
                    } label: {
                        Image(systemName: "xmark")
                            .buttonSymbolCircleSmall()
                    }
                    TransactionTagView(tag)
                    Spacer(minLength: 0)
                }
                .listRow()
                .listRowSeparator(.hidden)
            }
        }
    }

    @ViewBuilder private func TagsExcludeField() -> some View {
        NavigationLink {
            TransactionTagPickerView(budget: budget) { transactionsFilter.blacklistedTags.insert($0) }
        } label: {
            HStack {
                Text("Exclude Tags")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                AddTagButtonLabel(isInclude: false)
            }
        }
        .listRow()
        .accessibilityIdentifier("TransactionsFilterMenu.TagsExcludeFieldButton")
        if !transactionsFilter.blacklistedTags.isEmpty {
            ForEach(transactionsFilter.blacklistedTags.sorted { $0.value < $1.value }) { tag in
                HStack {
                    Button {
                        withAnimation(.snappy) { _ = transactionsFilter.blacklistedTags.remove(tag) }
                    } label: {
                        Image(systemName: "xmark")
                            .buttonSymbolCircleSmall()
                    }
                    TransactionTagView(tag)
                    Spacer(minLength: 0)
                }
                .listRow()
                .listRowSeparator(.hidden)
            }
        }
    }

    @ViewBuilder private func AddTagButtonLabel(isInclude: Bool) -> some View {
        HStack {
            Image(systemName: "tag")
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: isInclude ? "plus" : "minus")
                        .font(.system(size: 8))
                        .bold()
                        .foregroundStyle(Color.background)
                        .padding(.borderWidthThin)
                        .background {
                            Circle()
                                .foregroundStyle(Color.text)
                        }
                }
        }
        .buttonLabelSmall()
    }

    @ViewBuilder private func SeeTransactionsButton() -> some View {
        Button {
            withAnimation(.snappy) { isMenuVisible = false }
        } label: {
            Text("See \(transactionCount) Transactions")
                .frame(maxWidth: .infinity)
                .buttonLabelMedium(isProminent: true)
        }
    }

    @ViewBuilder func ClearAllButton() -> some View {
        Button {
            withAnimation(.snappy) { self.transactionsFilter = .none }
        } label: {
            Text("Clear Filters")
                .frame(maxWidth: .infinity)
                .buttonLabelMedium()
        }
    }

    @ViewBuilder func LocationField() -> some View {
        VStack {
            HStack {
                Text("Location Contains Text")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
            }
            TextField("Location Contains Text",
                      text: $transactionsFilter.locationContainsText,
                      prompt: Text("Seattle, WA, etc...").foregroundStyle(Color.text.opacity(.opacityTextFieldPrompt))
            )
            .overlay(alignment: .trailing) {
                Button {
                    transactionsFilter.locationContainsText = ""
                } label: {
                    Image(systemName: "xmark")
                        .buttonSymbolCircleSmall()
                }
                .opacity(transactionsFilter.locationContainsText.isEmpty ? 0 : 1)
            }
            .textFieldSmall()
        }
        .listRow()
    }

    @ViewBuilder func ContainsAnyTextField() -> some View {
        VStack {
            HStack {
                Text("Description Contains Text")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
            }
            TextField("Description Contains Text",
                      text: $transactionsFilter.descriptionContainsText,
                      prompt: Text("Milk Tea, Movie Tickets, etc...").foregroundStyle(Color.text.opacity(.opacityTextFieldPrompt))
            )
            .overlay(alignment: .trailing) {
                Button {
                    transactionsFilter.descriptionContainsText = ""
                } label: {
                    Image(systemName: "xmark")
                        .buttonSymbolCircleSmall()
                }
                .opacity(transactionsFilter.descriptionContainsText.isEmpty ? 0 : 1)
            }
            .textFieldSmall()
        }
        .listRow()
    }
}

#Preview {
    NavigationStack {
        StatefulPreviewContainer(TransactionsFilter.none) { filter in
            TransactionsFilterMenu(
                budget: Budget(info: .sample),
                isMenuVisible: .constant(true),
                transactionsFilter: filter,
                transactionCount: .constant(10)
            )
        }
    }
}
