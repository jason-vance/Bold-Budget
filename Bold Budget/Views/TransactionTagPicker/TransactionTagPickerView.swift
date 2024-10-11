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
    
    @State private var tags: Set<Transaction.Tag>? = nil
    @State private var searchText: String = ""
    @State private var searchPresented: Bool = false
    
    public var onSelected: (Transaction.Tag) -> ()
    
    private var filteredTags: [Transaction.Tag] {
        guard let tags = tags else { return [] }
        let sortedTags = tags.sorted { $0.value < $1.value }
        
        guard !searchText.isEmpty else {
            return sortedTags
        }
        
        return sortedTags
            .filter { $0.value.contains(searchText) }
    }
    
    private var tagsPublisher: AnyPublisher<Set<Transaction.Tag>,Never> {
        (iocContainer~>TransactionTagProvider.self)
            .tagsPublisher
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    private func select(tag: Transaction.Tag) {
        onSelected(tag)
        dismiss()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            SearchArea()
                .padding(.padding)
            BarDivider()
            ScrollView {
                LazyVStack {
                    if tags?.isEmpty == true {
                        NoTagsView()
                    } else if tags != nil {
                        ForEach(filteredTags) { tag in
                            TagButton(tag)
                        }
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.text)
                            .padding(.top, 100)
                    }
                }
                .padding(.padding)
            }
        }
        .background(Color.background)
        .onReceive(tagsPublisher) { tags = $0 }
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
    
    @ViewBuilder func TopBar() -> some View {
        ScreenTitleBar(
            primaryContent: { Text("Pick a Tag") },
            leadingContent: { CloseButton() },
            trailingContent: { CloseButton().opacity(0) }
        )
    }
    
    @ViewBuilder func CloseButton() -> some View {
        Button {
            dismiss()
        } label: {
            TitleBarButtonLabel(sfSymbol: "xmark")
        }
    }
    
    @ViewBuilder func SearchArea() -> some View {
        SearchBar(
            prompt: String(localized: "Search for a category"),
            searchText: $searchText,
            searchPresented: $searchPresented,
            action: {}
        )
    }
}

#Preview {
    TransactionTagPickerView() { tag in }
}
