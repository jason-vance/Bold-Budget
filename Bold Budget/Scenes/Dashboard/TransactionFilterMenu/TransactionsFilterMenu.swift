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
        category: nil,
        tags: []
    )
    
    var descriptionContainsText: String
    var category: Transaction.Category?
    var tags: Set<Transaction.Tag>
    
    var count: Int {
        var rv: Int = 0
        
        if !descriptionContainsText.isEmpty { rv += 1 }
        if category != nil { rv += 1 }
        rv += tags.count
        
        return rv
    }
    
    func shouldInclude(_ transaction: Transaction) -> Bool {
        let descriptionContainsText = descriptionContainsText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !descriptionContainsText.isEmpty, !transaction.description.lowercased().contains(descriptionContainsText) {
            return false
        }
        
        if let category = category, category != transaction.category {
            return false
        }
        
        if !tags.isEmpty && transaction.tags.intersection(tags).isEmpty {
            return false
        }
        
        return true
    }
}

struct TransactionsFilterMenu: View {
    
    @State var budget: Budget
    @Binding var isMenuVisible: Bool
    @Binding var transactionsFilter: TransactionsFilter
    @Binding var transactionCount: Int
    
    var body: some View {
        VStack {
            Form {
                Section {
                    ContainsAnyTextField()
                    CategoryField()
                    TagsField()
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
        .background(Color.background)
    }
    
    @ViewBuilder private func TagsField() -> some View {
        NavigationLink {
            TransactionTagPickerView { transactionsFilter.tags.insert($0) }
        } label: {
            HStack {
                Text("Tags")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                AddTagButtonLabel()
            }
        }
        .formRow()
        .accessibilityIdentifier("TransactionsFilterMenu.TagsFieldButton")
        if !transactionsFilter.tags.isEmpty {
            ForEach(transactionsFilter.tags.sorted { $0.value < $1.value }) { tag in
                HStack {
                    Button {
                        withAnimation(.snappy) { transactionsFilter.tags = transactionsFilter.tags.subtracting([tag]) }
                    } label: {
                        Image(systemName: "xmark")
                            .buttonSymbolCircleSmall()
                    }
                    TransactionTagView(tag)
                    Spacer(minLength: 0)
                }
                .formRow()
                .listRowSeparator(.hidden)
            }
        }
    }
    
    @ViewBuilder private func AddTagButtonLabel() -> some View {
        HStack {
            Image(systemName: "tag")
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "plus")
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
            Text("Clear All")
                .frame(maxWidth: .infinity)
                .buttonLabelMedium()
        }
    }
    
    @ViewBuilder func CategoryField() -> some View {
        NavigationLink {
            TransactionCategoryPickerView(
                budget: budget,
                selectedCategory: $transactionsFilter.category
            )
            .pickerMode(.picker)
        } label: {
            HStack {
                Text("Category")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
                if let category = transactionsFilter.category {
                    HStack {
                        HStack {
                            Image(systemName: category.sfSymbol.value)
                            Text(category.name.value)
                        }
                        .buttonLabelSmall()
                        ClearCategoryButton() // Inside the other button's label to allow two buttons in one form row
                    }
                } else {
                    Text(transactionsFilter.category?.name.value ?? "N/A")
                        .buttonLabelSmall()
                }
            }
        }
        .formRow()
    }
    
    @ViewBuilder func ClearCategoryButton() -> some View {
        Image(systemName: "xmark")
            .buttonSymbolCircleSmall()
            .onTapGesture {
                withAnimation(.snappy) { transactionsFilter.category = nil }
            }
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
                      prompt: Text("Milk Tea, Movie Tickets, etc...").foregroundStyle(Color.text.opacity(0.7))
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
        .formRow()
    }
}

#Preview {
    NavigationStack {
        StatefulPreviewContainer(TransactionsFilter.none) { filter in
            TransactionsFilterMenu(
                budget: .sample,
                isMenuVisible: .constant(true),
                transactionsFilter: filter,
                transactionCount: .constant(10)
            )
        }
    }
}
