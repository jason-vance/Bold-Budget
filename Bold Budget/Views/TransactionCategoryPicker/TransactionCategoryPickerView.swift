//
//  TransactionCategoryPickerView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Combine
import SwiftUI
import SwiftUIFlowLayout
import SwinjectAutoregistration

struct TransactionCategoryPickerView: View {
    
    enum Mode {
        case picker
        case pickerAndEditor
    }
    
    @Environment(\.dismiss) private var dismiss
    
    @State var mode: Mode = .picker
    @State private var categories: [Transaction.Category] = []
    @State private var searchText: String = ""
    @State private var searchPresented: Bool = false
    
    public var onSelected: (Transaction.Category) -> ()
    
    private let categoryProvider = iocContainer~>TransactionCategoryProvider.self
    
    private var filteredCategories: [Transaction.Category] {
        categories.filter { $0.name.contains(searchText) }
        //TODO: Sort categories too
    }
    
    private var categoriesPublisher: AnyPublisher<[Transaction.Category],Never> {
        categoryProvider
            .categoriesPublisher
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    private func select(category: Transaction.Category) {
        onSelected(category)
        dismiss()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            SearchArea()
                .padding(.padding)
            BarDivider()
            ScrollView {
                VStack {
                    FlowLayout(
                        mode: .scrollable,
                        items: filteredCategories.sorted { $0.name < $1.name },
                        itemSpacing: 0
                    ) { category in
                        Button {
                            select(category: category)
                        } label: {
                            Text(category.name)
                                .buttonLabelSmall()
                                .id(category.id)
                        }
                    }
                    if categories.isEmpty {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.text)
                            .padding(.top, 100)
                    }
                }
                .padding()
            }
        }
        .background(Color.background)
        .onReceive(categoriesPublisher) { categories = $0 }
    }
    
    @ViewBuilder func TopBar() -> some View {
        ScreenTitleBar(
            primaryContent: { Text("Pick a Category") },
            leadingContent: { CloseButton() },
            trailingContent: { AddButton() }
        )
    }
    
    @ViewBuilder func CloseButton() -> some View {
        Button {
            dismiss()
        } label: {
            TitleBarButtonLabel(sfSymbol: "xmark")
        }
    }
    
    @ViewBuilder func AddButton() -> some View {
        Button {
            //TODO: showAddTransactionCategoryView
        } label: {
            TitleBarButtonLabel(sfSymbol: "plus")
        }
        .opacity(mode == .pickerAndEditor ? 1 : 0)
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
    TransactionCategoryPickerView(mode: .pickerAndEditor) { _ in }
}
