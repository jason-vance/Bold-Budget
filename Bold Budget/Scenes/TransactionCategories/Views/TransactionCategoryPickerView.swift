//
//  TransactionCategoryPickerView.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/2/24.
//

import Combine
import SwiftUI
import SwinjectAutoregistration

/// Picks (or edits) a budget's transaction categories, redesign palette: a title header with a
/// close button and an edit toggle, a rounded search field, and a card of category rows. Self-
/// contained (own header + scroll) so it carries the redesign look without the shared List chrome,
/// mirroring `RecurringExpensesView`.
struct TransactionCategoryPickerView: View {

    enum Mode {
        case picker
        case editor
    }

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    @StateObject public var budget: Budget
    @Binding public var selectedCategoryId: Transaction.Category.Id?

    @State private var mode: Mode? = nil
    @State private var searchText: String = ""
    
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
            Header()
            SearchField()
            ScrollView {
                VStack(spacing: .padding) {
                    AdCard()
                    if budget.transactionCategories.isEmpty {
                        EmptyState()
                    } else if filteredCategories.isEmpty {
                        NoResults()
                    } else {
                        CategoriesList()
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .overlay(alignment: .bottomTrailing) { AddCategoryButton() }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .onChange(of: __mode, initial: true) { _, mode in set(mode: mode) }
        .onReceive(subscriptionLevelProvider.subscriptionLevelPublisher) { subscriptionLevel = $0 }
        .alert(alertMessage, isPresented: $showAlert) {}
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text(mode == .editor ? "Edit a Category" : "Pick a Category")
                .font(.headline)
                .foregroundStyle(Color.appText)
                .padding(.horizontal, .barHeight)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                }
                .accessibilityIdentifier("TransactionCategoryPickerView.CloseButton")
                Spacer(minLength: 0)
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Search

    @ViewBuilder private func SearchField() -> some View {
        HStack(spacing: .paddingSmall) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.appMutedText)
            TextField(
                "Search",
                text: $searchText,
                prompt: Text("Search for a category").foregroundStyle(Color.appMutedText)
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .tint(Color.brandTeal)
            .foregroundStyle(Color.appText)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.appMutedText)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                .foregroundStyle(Color.appSurface)
        }
        .padding(.horizontal)
        .padding(.bottom, .paddingSmall)
    }

    // MARK: - Ad

    @ViewBuilder private func AdCard() -> some View {
        if subscriptionLevel == SubscriptionLevel.none {
            NativeAdListRow(ad: $ad, size: .small)
                .frame(maxWidth: .infinity)
                .card()
        }
    }

    // MARK: - Categories

    @ViewBuilder private func CategoriesList() -> some View {
        VStack(spacing: 0) {
            ForEach(filteredCategories) { category in
                CategoryButton(category)
            }
        }
    }

    @ViewBuilder private func CategoryButton(_ category: Transaction.Category) -> some View {
        if mode == .editor {
            NavigationLink {
                EditTransactionCategoryView(budget: budget)
                    .editing(category)
            } label: {
                CategoryRow(category)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                select(category: category)
            } label: {
                CategoryRow(category)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder private func CategoryRow(_ category: Transaction.Category) -> some View {
        HStack(spacing: .padding) {
            IconCircle(systemName: category.sfSymbol.value, size: 40, tint: .brandTeal)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name.value)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appText)
                if let goal = category.goal {
                    Text(goalSubtitle(goal))
                        .font(.caption)
                        .foregroundStyle(Color.appMutedText)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            TrailingIndicator(category)
        }
        .padding(.padding)
        .contentShape(Rectangle())
    }

    private func goalSubtitle(_ goal: Transaction.Category.Goal) -> String {
        let symbol = goal.comparison == .lessThan ? "<" : "≥"
        return "Goal: \(symbol) \(goal.amount.formattedRounded())/\(goal.period.toUiString())"
    }

    @ViewBuilder private func TrailingIndicator(_ category: Transaction.Category) -> some View {
        if mode == .editor {
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appMutedText)
        }
    }

    // MARK: - Empty states

    @ViewBuilder private func EmptyState() -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(systemName: "list.bullet", size: 56, tint: .brandTeal)
            Text("No Categories")
                .font(.title3.weight(.bold))
            Text("Any categories you add will show up here.")
                .font(.subheadline)
                .foregroundStyle(Color.appMutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .padding * 2)
    }

    @ViewBuilder private func NoResults() -> some View {
        VStack(spacing: .paddingSmall) {
            IconCircle(systemName: "magnifyingglass", size: 56, tint: .brandTeal)
            Text("No Matches")
                .font(.title3.weight(.bold))
            Text("No categories match \u{201C}\(searchText)\u{201D}.")
                .font(.subheadline)
                .foregroundStyle(Color.appMutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .padding * 2)
    }

    // MARK: - Add

    @ViewBuilder private func AddCategoryButton() -> some View {
        NavigationLink {
            EditTransactionCategoryView(budget: budget)
        } label: {
            Image(systemName: "plus")
                .font(.title.weight(.semibold))
                .foregroundStyle(Color.appBackground)
                .padding()
                .background {
                    Circle()
                        .foregroundStyle(Color.brandTeal)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                }
        }
        .padding()
        .accessibilityIdentifier("TransactionCategoryPickerView.AddCategoryButton")
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
    .environmentObject(AdProviderFactory.forScreenshots)
}

#Preview("Editor") {
    NavigationStack {
        TransactionCategoryPickerView(
            budget: Budget(info: .sample),
            selectedCategoryId: .constant(nil),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
        .pickerMode(.editor)
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}
