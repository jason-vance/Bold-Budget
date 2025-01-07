//
//  TransactionCategoryPickerView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Combine
import SwiftUI
import SwinjectAutoregistration

struct TransactionCategoryPickerView: View {
    
    enum Mode {
        case picker
        case pickerAndEditor
        case editor
    }
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject public var budget: Budget
    @Binding public var selectedCategoryId: Transaction.Category.Id?
    
    @State private var mode: Mode? = nil
    @State private var searchText: String = ""
    @State private var searchPresented: Bool = false
    @State private var isEditing: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @State private var subscriptionLevel: SubscriptionLevel = .none
    private let subscriptionLevelProvider: SubscriptionLevelProvider
    
    private var __mode: Mode?

    public func pickerMode(_ mode: Mode) -> TransactionCategoryPickerView {
        var view = self
        view.__mode = mode
        return view
    }
    
    init(
        budget: Budget,
        selectedCategoryId: Binding<Transaction.Category.Id?>
    ) {
        self.init(
            budget: budget,
            selectedCategoryId: selectedCategoryId,
            subscriptionLevelProvider: iocContainer~>SubscriptionLevelProvider.self
        )
    }
    
    init(
        budget: Budget,
        selectedCategoryId: Binding<Transaction.Category.Id?>,
        subscriptionLevelProvider: SubscriptionLevelProvider
    ) {
        self._budget = .init(wrappedValue: budget)
        self._selectedCategoryId = selectedCategoryId
        self.subscriptionLevelProvider = subscriptionLevelProvider
    }
    
    private var filteredCategories: [Transaction.Category] {
        let sortedCategories = budget.transactionCategories.values.sorted { $0.name.value < $1.name.value }
        
        guard !searchText.isEmpty else {
            return sortedCategories
        }
        
        return sortedCategories
            .filter { $0.name.value.contains(searchText) }
    }
    
    private func set(mode: Mode?) {
        self.mode = mode
        
        if mode == .editor {
            isEditing = true
        }
    }
    
    private func select(category: Transaction.Category) {
        selectedCategoryId = category.id
        dismiss()
    }
    
    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SearchArea()
            BarDivider()
            List {
                AdSection()
                if budget.transactionCategories.isEmpty {
                    NoCategoriesView()
                } else {
                    ForEach(filteredCategories) { category in
                        CategoryButton(category)
                            .listRowNoChrome()
                            .listRowInsets(.init(top: 0,
                                                 leading: 0,
                                                 bottom: 0,
                                                 trailing: 0))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .overlay(alignment: .bottomTrailing) { AddCategoryButton() }
        }
        .toolbar { Toolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(isEditing ? "Edit a Category" : "Pick a Category")
        .navigationBarBackButtonHidden()
        .foregroundStyle(Color.text)
        .background(Color.background)
        .onChange(of: __mode, initial: true) { _, mode in set(mode: mode) }
        .onReceive(subscriptionLevelProvider.subscriptionLevelPublisher) { subscriptionLevel = $0 }
        .alert(alertMessage, isPresented: $showAlert) {}
    }
    
    @ViewBuilder func AdSection() -> some View {
        if subscriptionLevel == SubscriptionLevel.none {
            Section {
                SimpleNativeAdView(size: .small)
                    .listRow()
            }
        }
    }
    
    @ViewBuilder func NoCategoriesView() -> some View {
        ContentUnavailableView(
            "No Categories",
            systemImage: "list.bullet",
            description: Text("Any categories you add will show up here")
        )
        .listRowNoChrome()
    }
    
    @ViewBuilder private func LoadingSpinner() -> some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.text)
            Spacer()
        }
        .padding(.top, 100)
        .listRowNoChrome()
    }
    
    @ViewBuilder func CategoryButton(_ category: Transaction.Category) -> some View {
        if isEditing {
            NavigationLink {
                EditTransactionCategoryView(budget: budget)
                    .editing(category)
            } label: {
                CategoryButtonLabel(category)
            }
        } else {
            Button {
                select(category: category)
            } label: {
                CategoryButtonLabel(category)
            }
        }
    }
    
    @ViewBuilder private func CategoryButtonLabel(_ category: Transaction.Category) -> some View {
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
    
    @ViewBuilder func CategoryButtonIsEditingIndicator() -> some View {
        if isEditing {
            Image(systemName: "pencil")
                .bold()
                .frame(width: 22, height: 22)
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
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            CloseButton()
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            if mode != .editor {
                EditButton()
            }
        }
    }
    
    @ViewBuilder func CloseButton() -> some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
        }
    }
    
    @ViewBuilder private func EditButton() -> some View {
        Button {
            withAnimation(.snappy) { isEditing.toggle() }
        } label: {
            Image(systemName: isEditing ? "pencil.slash" : "pencil")
        }
        .opacity(mode == .pickerAndEditor && budget.transactionCategories.isEmpty ? 0 : 1)
        .accessibilityIdentifier("TransactionCategoryPickerView.Toolbar.EditButton")
    }
    
    @ViewBuilder func AddCategoryButton() -> some View {
        NavigationLink {
            EditTransactionCategoryView(budget: budget)
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
        .padding()
        .accessibilityIdentifier("TransactionCategoryPickerView.AddCategoryButton")
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

#Preview("Picker") {
    NavigationStack {
        TransactionCategoryPickerView(
            budget: Budget(info: .sample),
            selectedCategoryId: .constant(nil),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
        .pickerMode(.picker)
    }
}

#Preview("Picker And Editor") {
    NavigationStack {
        TransactionCategoryPickerView(
            budget: Budget(info: .sample),
            selectedCategoryId: .constant(nil),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
        .pickerMode(.pickerAndEditor)
    }
}
