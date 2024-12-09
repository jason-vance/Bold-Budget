//
//  TransactionTagPickerView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/10/24.
//

import Combine
import SwinjectAutoregistration
import SwiftUI

struct TransactionTagPickerView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var budget: Budget
    @State private var searchText: String = ""
    @State private var searchPresented: Bool = false
    
    public var onSelected: (Transaction.Tag) -> ()
    
    private var filteredTags: [Transaction.Tag] {
        let sortedTags = budget.transactionTags.sorted { $0.value < $1.value }
        
        guard !searchText.isEmpty else {
            return sortedTags
        }
        
        return sortedTags
            .filter { $0.value.contains(searchText) }
    }
    
    private func select(tag: Transaction.Tag) {
        onSelected(tag)
        dismiss()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SearchArea()
            BarDivider()
            ScrollView {
                LazyVStack {
                    if budget.transactionTags.isEmpty {
                        NoTagsView()
                    } else {
                        ForEach(filteredTags) { tag in
                            TagButton(tag)
                        }
                    }
                }
                .padding()
            }
        }
        .toolbar { Toolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Pick a Tag")
        .navigationBarBackButtonHidden()
        .foregroundStyle(Color.text)
        .background(Color.background)
    }
    
    @ViewBuilder func NoTagsView() -> some View {
        ContentUnavailableView(
            "No Tags",
            systemImage: "list.bullet",
            description: Text("Any tags you add to your transactions will show up here")
        )
        .foregroundStyle(Color.text)
        .listRowBackground(Color.background)
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder func TagButton(_ tag: Transaction.Tag) -> some View {
        HStack {
            Button {
                select(tag: tag)
            } label: {
                TransactionTagView(tag)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, .paddingVerticalButtonXSmall)
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            CloseButton()
        }
    }
    
    @ViewBuilder func CloseButton() -> some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.backward")
        }
    }
    
    @ViewBuilder func SearchArea() -> some View {
        SearchBar(
            prompt: String(localized: "Search for a category"),
            searchText: $searchText,
            searchPresented: $searchPresented,
            action: {}
        )
        .padding(.horizontal)
        .padding(.vertical, .padding)
    }
}

#Preview {
    NavigationStack {
        TransactionTagPickerView(budget: Budget(info: .sample)) { tag in }
    }
}
