//
//  EditRecurringExpenseView.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/15/26.
//

import SwiftUI
import SwinjectAutoregistration

struct EditRecurringExpenseView: View {

    private struct OptionalExpense: Equatable {
        let expense: RecurringExpense?
        static let none: OptionalExpense = .init(expense: nil)
    }

    private static let cycleOptions: [Int] = [1, 3, 6, 12]

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    @State private var screenTitle: String = String(localized: "Add Recurring Expense")
    @State private var kind: RecurringExpense.Kind = .bill
    @State private var nameString: String = ""
    @State private var nameInstructions: String = ""
    @State private var price: Money = .zero
    @State private var monthsPerCycle: Int = 1
    @State private var remainingBalance: Money = .zero
    @State private var categoryId: Transaction.Category.Id? = nil

    @State private var showPriceEntryView: Bool = false
    @State private var showBalanceEntryView: Bool = false

    @State private var showDeleteConfirmation: Bool = false

    @State private var subscriptionLevel: SubscriptionLevel = .none
    private let subscriptionLevelProvider: SubscriptionLevelProvider

    private var expenseToEdit: OptionalExpense = .none

    @StateObject var budget: Budget

    init(
        budget: Budget
    ) {
        self.init(
            budget: budget,
            subscriptionLevelProvider: iocContainer~>SubscriptionLevelProvider.self
        )
    }

    init(
        budget: Budget,
        subscriptionLevelProvider: SubscriptionLevelProvider
    ) {
        self._budget = .init(wrappedValue: budget)
        self.subscriptionLevelProvider = subscriptionLevelProvider
    }

    public func editing(_ expense: RecurringExpense) -> EditRecurringExpenseView {
        var view = self
        view.expenseToEdit = .init(expense: expense)
        return view
    }

    private var expense: RecurringExpense? {
        guard let name = RecurringExpense.Name(nameString) else { return nil }

        let balance: Money? = {
            guard kind == .debt else { return nil }
            guard remainingBalance.amount > 0 else { return nil }
            return remainingBalance
        }()

        return .init(
            id: expenseToEdit.expense?.id ?? RecurringExpense.Id(),
            name: name,
            kind: kind,
            price: price,
            monthsPerCycle: monthsPerCycle,
            remainingBalance: balance,
            categoryId: categoryId
        )
    }

    private var isFormComplete: Bool { expense != nil }

    private func saveExpense() {
        guard let expense = expense else { return }
        budget.save(recurringExpense: expense)
        dismiss()
    }

    private func deleteExpense() {
        guard let expense = expenseToEdit.expense else { return }
        budget.remove(recurringExpense: expense)
        dismiss()
    }

    private func setNameInstructions(_ nameString: String) {
        withAnimation(.snappy) {
            if nameString.isEmpty { nameInstructions = ""; return }
            if nameString.count > RecurringExpense.Name.maxTextLength { nameInstructions = "Too long"; return }
            nameInstructions = "\(nameString.count)/\(RecurringExpense.Name.maxTextLength)"
        }
    }

    private func populateFields(_ expense: OptionalExpense) {
        guard let expense = expense.expense else { return }
        let isFormEmpty = nameString.isEmpty
        guard isFormEmpty else { return }

        screenTitle = String(localized: "Edit Recurring Expense")
        kind = expense.kind
        nameString = expense.name.value
        price = expense.price
        monthsPerCycle = expense.monthsPerCycle
        remainingBalance = expense.remainingBalance ?? .zero
        categoryId = expense.categoryId
    }

    private func cycleName(_ months: Int) -> String {
        switch months {
        case 1: String(localized: "Monthly")
        case 12: String(localized: "Yearly")
        default: String(localized: "Every \(months) months")
        }
    }

    var body: some View {
        Form {
            AdSection()
            Section {
                NameField()
                KindField()
            } header: {
                Text("")
                    .foregroundStyle(Color.text)
            }
            Section {
                PriceField()
                BillingCycleField()
            } header: {
                Text("Cost")
                    .foregroundStyle(Color.text)
            }
            BalanceSection()
            CategorySection()
            DeleteSection()
        }
        .scrollDismissesKeyboard(.immediately)
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .toolbar { Toolbar() }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(screenTitle)
        .foregroundStyle(Color.text)
        .background(Color.background.ignoresSafeArea())
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .confirmationDialog(
            "Delete '\(expenseToEdit.expense?.name.value ?? "")'?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteExpense()
            }
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: nameString) { _, nameString in setNameInstructions(nameString) }
        .onChange(of: expenseToEdit, initial: true) { _, expense in populateFields(expense) }
        .onReceive(subscriptionLevelProvider.subscriptionLevelPublisher) { subscriptionLevel = $0 }
        .animation(.snappy, value: kind)
    }

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            SaveButton()
        }
    }

    @ViewBuilder private func SaveButton() -> some View {
        Button {
            saveExpense()
        } label: {
            Image(systemName: "checkmark")
        }
        .opacity(isFormComplete ? 1 : .opacityButtonBackground)
        .disabled(!isFormComplete)
        .accessibilityIdentifier("EditRecurringExpenseView.Toolbar.SaveButton")
    }

    @ViewBuilder private func AdSection() -> some View {
        if subscriptionLevel == SubscriptionLevel.none {
            Section {
                NativeAdListRow(ad: $ad, size: .small)
                    .listRow()
            }
        }
    }

    @ViewBuilder private func NameField() -> some View {
        VStack {
            HStack {
                Text("Name")
                    .foregroundStyle(Color.text)
                Spacer(minLength: 0)
            }
            TextField("Name",
                      text: $nameString,
                      prompt: Text(RecurringExpense.Name.sample.value).foregroundStyle(Color.text.opacity(.opacityTextFieldPrompt))
            )
            .textFieldSmall()
            .autocapitalization(.words)
            .accessibilityIdentifier("EditRecurringExpenseView.NameField.TextField")
            HStack {
                Spacer(minLength: 0)
                Text(nameInstructions)
                    .font(.caption2)
                    .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    .padding(.horizontal, .paddingHorizontalButtonXSmall)
            }
        }
        .listRow()
    }

    @ViewBuilder private func KindField() -> some View {
        HStack {
            Text("Type")
                .foregroundStyle(Color.text)
            Spacer(minLength: 0)
            Menu {
                ForEach(RecurringExpense.Kind.allCases, id: \.self) { option in
                    Button {
                        kind = option
                    } label: {
                        HStack {
                            Text(option.name)
                            if kind == option { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                Text(kind.name)
                    .buttonLabelSmall()
            }
        }
        .listRow()
    }

    @ViewBuilder private func PriceField() -> some View {
        HStack {
            Text("Price")
                .foregroundStyle(Color.text)
            Spacer(minLength: 0)
            Button {
                showPriceEntryView = true
            } label: {
                HStack {
                    Spacer(minLength: 0)
                    Text(price.formatted())
                        .multilineTextAlignment(.trailing)
                }
            }
            .frame(width: 128)
            .textFieldSmall()
            .accessibilityIdentifier("EditRecurringExpenseView.PriceField.TextField")
        }
        .listRow()
        .fullScreenCover(isPresented: $showPriceEntryView) {
            MoneyFieldEntryView(
                title: "Price",
                money: $price,
                suggestions: budget.recurringExpenses.values.map(\.price)
            )
        }
    }

    @ViewBuilder private func BillingCycleField() -> some View {
        HStack {
            Text("Billed")
                .foregroundStyle(Color.text)
            Spacer(minLength: 0)
            Menu {
                ForEach(Self.cycleOptions, id: \.self) { months in
                    Button {
                        monthsPerCycle = months
                    } label: {
                        HStack {
                            Text(cycleName(months))
                            if monthsPerCycle == months { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                Text(cycleName(monthsPerCycle))
                    .buttonLabelSmall()
                    .contentTransition(.numericText())
            }
        }
        .listRow()
    }

    @ViewBuilder private func BalanceSection() -> some View {
        if kind == .debt {
            Section {
                HStack {
                    Text("Amount")
                        .foregroundStyle(Color.text)
                    Spacer(minLength: 0)
                    Button {
                        showBalanceEntryView = true
                    } label: {
                        HStack {
                            Spacer(minLength: 0)
                            Text(remainingBalance.formatted())
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .frame(width: 128)
                    .textFieldSmall()
                    .accessibilityIdentifier("EditRecurringExpenseView.BalanceField.TextField")
                }
                .listRow()
                .fullScreenCover(isPresented: $showBalanceEntryView) {
                    MoneyFieldEntryView(
                        title: "Still Owed",
                        money: $remainingBalance
                    )
                }
            } header: {
                Text("Still Owed")
                    .foregroundStyle(Color.text)
            }
        }
    }

    @ViewBuilder private func CategorySection() -> some View {
        Section {
            NavigationLink {
                TransactionCategoryPickerView(
                    budget: budget,
                    selectedCategoryId: $categoryId
                )
                .pickerMode(.pickerAndEditor)
            } label: {
                HStack {
                    Text("Category")
                        .foregroundStyle(Color.text)
                    Spacer(minLength: 0)
                    Text(selectedCategoryName)
                        .buttonLabelSmall()
                }
            }
            .listRow()
            .accessibilityIdentifier("EditRecurringExpenseView.CategoryField.SelectCategoryButton")
            if categoryId != nil {
                Button {
                    categoryId = nil
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Unlink Category")
                        Spacer(minLength: 0)
                    }
                }
                .listRow()
            }
        } header: {
            Text("Linked Category (Optional)")
                .foregroundStyle(Color.text)
        }
    }

    private var selectedCategoryName: String {
        guard let categoryId else { return String(localized: "None") }
        return budget.getCategoryBy(id: categoryId).name.value
    }

    @ViewBuilder private func DeleteSection() -> some View {
        if expenseToEdit.expense != nil {
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Recurring Expense")
                        Spacer(minLength: 0)
                    }
                }
                .listRow()
                .accessibilityIdentifier("EditRecurringExpenseView.DeleteButton")
            }
        }
    }
}

#Preview("New") {
    NavigationStack {
        EditRecurringExpenseView(
            budget: .previewSample(),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}

#Preview("Edit Debt") {
    NavigationStack {
        EditRecurringExpenseView(
            budget: .previewSample(recurringExpenses: RecurringExpense.samples),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
        .editing(.sampleCarLoan)
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}

#Preview("Edit Annual Subscription") {
    NavigationStack {
        EditRecurringExpenseView(
            budget: .previewSample(recurringExpenses: RecurringExpense.samples),
            subscriptionLevelProvider: MockSubscriptionLevelProvider(level: .boldBudgetPlus)
        )
        .editing(.sampleAnnualSubscription)
    }
    .environmentObject(AdProviderFactory.forScreenshots)
}
