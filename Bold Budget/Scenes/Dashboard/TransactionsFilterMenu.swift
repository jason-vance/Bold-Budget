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
        category: nil
    )
    
    var descriptionContainsText: String
    var category: Transaction.Category?
    
    var count: Int {
        var rv: Int = 0
        
        if !descriptionContainsText.isEmpty { rv += 1 }
        if category != nil { rv += 1 }
        
        return rv
    }
    
    func shouldInclude(_ transaction: Transaction) -> Bool {
        if !descriptionContainsText.isEmpty,
           !transaction.description.lowercased().contains(descriptionContainsText.lowercased())
        {
            return false
        }
        
        if let category = category, category != transaction.category {
            return false
        }
        
        return true
    }
}

struct TransactionsFilterMenu: View {
    
    @Binding var isMenuVisible: Bool
    @Binding var transactionsFilter: TransactionsFilter
    @Binding var transactionCount: Int
    
    @State private var showCategoryPicker: Bool = false
    
    var body: some View {
        VStack {
            Form {
                Section {
                    ContainsAnyTextField()
                    CategoryField()
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
        .background(Color.background)
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
        HStack {
            Text("Category")
                .foregroundStyle(Color.text)
            Spacer(minLength: 0)
            Button {
                showCategoryPicker = true
            } label: {
                if let category = transactionsFilter.category {
                    HStack {
                        HStack {
                            Image(systemName: category.sfSymbol.value)
                            Text(category.name.value)
                        }
                        .buttonLabelSmall()
                        ClearCategoryButton()
                    }
                } else {
                    Text(transactionsFilter.category?.name.value ?? "N/A")
                        .buttonLabelSmall()
                }
            }
        }
        .formRow()
        .fullScreenCover(isPresented: $showCategoryPicker) {
            TransactionCategoryPickerView(mode: .picker) { transactionsFilter.category = $0 }
        }
    }
    
    @ViewBuilder func ClearCategoryButton() -> some View {
        Button {
            withAnimation(.snappy) { transactionsFilter.category = nil }
        } label: {
            Image(systemName: "xmark")
                .buttonSymbolCircleSmall()
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
    StatefulPreviewContainer(TransactionsFilter.none) { filter in
        TransactionsFilterMenu(
            isMenuVisible: .constant(true),
            transactionsFilter: filter,
            transactionCount: .constant(10)
        )
    }
}
