//
//  TransactionsFilterMenu.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/5/24.
//

import SwiftUI

struct TransactionsFilter {
    
    static let none: TransactionsFilter = .init(
        category: nil
    )
    
    var category: Transaction.Category?
    
    var count: Int {
        var rv: Int = 0
        
        if category != nil { rv += 1 }
        
        return rv
    }
    
    func shouldInclude(_ transaction: Transaction) -> Bool {
        if let category = category, category != transaction.category {
            return false
        }
        
        return true
    }
}

struct TransactionsFilterMenu: View {
    
    @Binding var transactionsFilter: TransactionsFilter
    
    @State private var showCategoryPicker: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    CategoryField()
                } header: {
                    Text("Filter Transactions")
                        .foregroundStyle(Color.text)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .background(Color.background)
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
}

#Preview {
    StatefulPreviewContainer(TransactionsFilter.none) { filter in
        TransactionsFilterMenu(transactionsFilter: filter)
    }
}
