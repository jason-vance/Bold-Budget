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
    @State private var categories: [Transaction.Category]? = nil
    @State private var searchText: String = ""
    @State private var searchPresented: Bool = false
    @State private var showAddTransactionCategoryView: Bool = false
    @State private var isEditing: Bool = false
    @State private var categoryToEdit: Transaction.Category? = nil
    
    public var onSelected: (Transaction.Category) -> ()
    
    private let categoryProvider = iocContainer~>TransactionCategoryRepo.self
    
    private var filteredCategories: [Transaction.Category] {
        guard let categories = categories else { return [] }
        let sortedCategories = categories.sorted { $0.name.value < $1.name.value }
        
        guard !searchText.isEmpty else {
            return sortedCategories
        }
        
        return sortedCategories
            .filter { $0.name.value.contains(searchText) }
    }
    
    private var categoriesPublisher: AnyPublisher<[Transaction.Category],Never> {
        categoryProvider
            .categoriesPublisher
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    private func select(category: Transaction.Category) {
        if isEditing {
            categoryToEdit = category
        } else {
            onSelected(category)
            dismiss()
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            SearchArea()
                .padding(.padding)
            BarDivider()
            ScrollView {
                LazyVStack {
                    if categories?.isEmpty == true {
                        NoCategoriesView()
                    } else if categories != nil {
                        ForEach(filteredCategories) { category in
                            CategoryButton(category)
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
            .safeAreaInset(edge: .bottom, alignment: .trailing) { AddCategoryButton() }
        }
        .background(Color.background)
        .onReceive(categoriesPublisher) { categories = $0 }
    }
    
    @ViewBuilder func NoCategoriesView() -> some View {
        ContentUnavailableView(
            "No Categories",
            systemImage: "list.bullet",
            description: Text("Any categories you add will show up here")
        )
        .foregroundStyle(Color.text)
        .listRowBackground(Color.background)
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder func CategoryButton(_ category: Transaction.Category) -> some View {
        HStack {
            Button {
                select(category: category)
            } label: {
                HStack {
                    KindIndicator(category.kind)
                    HStack {
                        Image(systemName: category.sfSymbol.value)
                        Text(category.name.value)
                    }
                    .buttonLabelSmall()
                    Spacer(minLength: 0)
                    CategoryButtonIsEditingIndicator()
                }
            }
            Spacer(minLength: 0)
        }
    }
    
    @ViewBuilder func CategoryButtonIsEditingIndicator() -> some View {
        if isEditing {
            Image(systemName: "pencil")
                .bold()
                .frame(width: 22, height: 22)
                .padding(.padding)
        }
    }
    
    @ViewBuilder func KindIndicator(_ kind: Transaction.Category.Kind) -> some View {
        HStack(spacing: 0) {
            Image(systemName: "dollarsign")
                .offset(x: 2)
        }
        .overlay {
            Image(systemName: kind == .expense ? "minus" : "plus")
                .font(.caption2.bold())
                .offset(x: -7)
        }
        .frame(width: 22, height: 22)
        .foregroundStyle(Color.background)
        .padding(.padding)
        .background {
            Circle().foregroundStyle(Color.text)
        }
    }
    
    @ViewBuilder func TopBar() -> some View {
        ScreenTitleBar(
            primaryContent: { Text(isEditing ? "Edit a Category" : "Pick a Category") },
            leadingContent: { CloseButton() },
            trailingContent: { EditButton() }
        )
    }
    
    @ViewBuilder func CloseButton() -> some View {
        Button {
            dismiss()
        } label: {
            TitleBarButtonLabel(sfSymbol: "xmark")
        }
    }
    
    @ViewBuilder private func EditButton() -> some View {
        Button {
            withAnimation(.snappy) { isEditing.toggle() }
        } label: {
            TitleBarButtonLabel(sfSymbol: isEditing ? "pencil.slash" : "pencil")
        }
        .opacity(mode == .pickerAndEditor && categories?.isEmpty == false ? 1 : 0)
        .fullScreenCover(isPresented: .init(
            get: { categoryToEdit != nil },
            set: { isPresented in categoryToEdit = isPresented ? categoryToEdit : nil }
        )) {
            if let category = categoryToEdit {
                AddTransactionCategoryView()
                    .editing(category)
            }
        }
    }
    
    @ViewBuilder func AddCategoryButton() -> some View {
        Button {
            showAddTransactionCategoryView = true
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(Color.background)
                .font(.title)
                .padding()
                .background {
                    Circle()
                        .foregroundStyle(Color.text)
                        .shadow(color: Color.background, radius: .padding)
                }
        }
        .opacity(mode == .pickerAndEditor && isEditing == false ? 1 : 0)
        .padding()
        .fullScreenCover(isPresented: $showAddTransactionCategoryView) {
            AddTransactionCategoryView()
        }
        .accessibilityIdentifier("Add Category Button")
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

#Preview("Picker") {
    TransactionCategoryPickerView(mode: .picker) { _ in }
}

#Preview("Picker And Editor") {
    TransactionCategoryPickerView(mode: .pickerAndEditor) { _ in }
}
