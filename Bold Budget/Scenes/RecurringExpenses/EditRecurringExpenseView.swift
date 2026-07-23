//
//  EditRecurringExpenseView.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/15/26.
//

import SwiftUI

struct EditRecurringExpenseView: View {

    private struct OptionalExpense: Equatable {
        let expense: RecurringExpense?
        static let none: OptionalExpense = .init(expense: nil)
    }

    private static let cycleOptions: [Int] = [1, 3, 6, 12]

    @Environment(\.dismiss) private var dismiss

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
    @State private var showConvertConfirmation: Bool = false

    private var expenseToEdit: OptionalExpense = .none

    @StateObject var budget: Budget

    init(budget: Budget) {
        self._budget = .init(wrappedValue: budget)
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

    private var isEditingExisting: Bool { expenseToEdit.expense != nil }

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

    /// Debts are being folded into liability accounts. Existing debts have `.debt` available; new
    /// recurring expenses are limited to bills and subscriptions.
    private var availableKinds: [RecurringExpense.Kind] {
        expenseToEdit.expense?.kind == .debt
            ? RecurringExpense.Kind.allCases
            : RecurringExpense.Kind.allCases.filter { $0 != .debt }
    }

    private var canConvertToAccount: Bool {
        expenseToEdit.expense?.kind == .debt
    }

    /// Turns a recurring debt into a liability `Account` — its remaining balance becomes the
    /// account balance and its price becomes the monthly payment — then removes the debt.
    private func convertDebtToAccount() {
        guard let expense = expenseToEdit.expense, expense.kind == .debt else { return }
        guard let accountName = Account.Name(expense.name.value) else { return }

        let account = Account(
            id: Account.Id(),
            name: accountName,
            kind: .loan,
            trackingMode: .snapshot,
            balance: expense.remainingBalance ?? .zero,
            monthlyPayment: expense.price.amount > 0 ? expense.price : nil
        )
        budget.save(account: account)
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
        guard nameString.isEmpty else { return }

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

    private func symbol(for kind: RecurringExpense.Kind) -> String {
        switch kind {
        case .debt: "creditcard.fill"
        case .bill: "doc.text.fill"
        case .subscription: "arrow.triangle.2.circlepath"
        }
    }

    private var selectedCategoryName: String {
        guard let categoryId else { return String(localized: "None") }
        return budget.getCategoryBy(id: categoryId).name.value
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Header()
            ScrollView {
                VStack(spacing: .padding) {
                    Profile()
                    NameField()
                    KindField()
                    PriceField()
                    BillingCycleField()
                    if kind == .debt {
                        BalanceField()
                    }
                    CategoryField()
                    if canConvertToAccount {
                        ConvertToAccountButton()
                    }
                    if isEditingExisting {
                        DeleteButton()
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .fullScreenCover(isPresented: $showPriceEntryView) {
            MoneyFieldEntryView(
                title: "Price",
                money: $price,
                suggestions: budget.recurringExpenses.values.map(\.price)
            )
        }
        .fullScreenCover(isPresented: $showBalanceEntryView) {
            MoneyFieldEntryView(
                title: "Still Owed",
                money: $remainingBalance
            )
        }
        .confirmationDialog(
            "Delete '\(expenseToEdit.expense?.name.value ?? "")'?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteExpense() }
            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog(
            "Convert '\(expenseToEdit.expense?.name.value ?? "")' to a liability account?",
            isPresented: $showConvertConfirmation,
            titleVisibility: .visible
        ) {
            Button("Convert") { convertDebtToAccount() }
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: nameString) { _, nameString in setNameInstructions(nameString) }
        .onChange(of: expenseToEdit, initial: true) { _, expense in populateFields(expense) }
        .animation(.snappy, value: kind)
    }

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text(screenTitle)
                .font(.headline)
                .foregroundStyle(Color.appText)
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.appMutedText)
                Spacer(minLength: 0)
                Button("Save") { saveExpense() }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandTeal)
                    .opacity(isFormComplete ? 1 : .opacityButtonBackground)
                    .disabled(!isFormComplete)
                    .accessibilityIdentifier("EditRecurringExpenseView.Toolbar.SaveButton")
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    @ViewBuilder private func Profile() -> some View {
        IconCircle(systemName: symbol(for: kind), size: 64, tint: .brandTeal)
            .frame(maxWidth: .infinity)
            .padding(.top, .paddingSmall)
    }

    @ViewBuilder private func FieldCard<Content: View>(
        _ label: LocalizedStringKey,
        footer: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .kerning(0.5)
                .foregroundStyle(Color.appMutedText)
            content()
            if let footer {
                Text(footer)
                    .font(.caption2)
                    .foregroundStyle(Color.appMutedText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                .foregroundStyle(Color.appSurface)
        }
    }

    @ViewBuilder private func NameField() -> some View {
        FieldCard("Name", footer: nameInstructions.isEmpty ? nil : LocalizedStringKey(nameInstructions)) {
            TextField(
                "Name",
                text: $nameString,
                prompt: Text(RecurringExpense.Name.sample.value).foregroundStyle(Color.appMutedText)
            )
            .font(.title3)
            .foregroundStyle(Color.appText)
            .tint(Color.brandTeal)
            .autocapitalization(.words)
            .accessibilityIdentifier("EditRecurringExpenseView.NameField.TextField")
        }
    }

    @ViewBuilder private func KindField() -> some View {
        FieldCard("Type") {
            Menu {
                ForEach(availableKinds, id: \.self) { option in
                    Button {
                        kind = option
                    } label: {
                        HStack {
                            Image(systemName: symbol(for: option))
                            Text(option.name)
                            if kind == option { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                MenuLabel(systemName: symbol(for: kind), text: kind.name)
            }
            .accessibilityIdentifier("EditRecurringExpenseView.KindField.Menu")
        }
    }

    @ViewBuilder private func PriceField() -> some View {
        FieldCard("Price") {
            Button {
                showPriceEntryView = true
            } label: {
                ValueLabel(text: price.formatted())
            }
            .accessibilityIdentifier("EditRecurringExpenseView.PriceField.TextField")
        }
    }

    @ViewBuilder private func BillingCycleField() -> some View {
        FieldCard("Billed") {
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
                MenuLabel(systemName: "calendar", text: cycleName(monthsPerCycle))
            }
            .accessibilityIdentifier("EditRecurringExpenseView.BillingCycleField.Menu")
        }
    }

    @ViewBuilder private func BalanceField() -> some View {
        FieldCard("Still Owed") {
            Button {
                showBalanceEntryView = true
            } label: {
                ValueLabel(text: remainingBalance.formatted())
            }
            .accessibilityIdentifier("EditRecurringExpenseView.BalanceField.TextField")
        }
    }

    @ViewBuilder private func CategoryField() -> some View {
        FieldCard("Linked Category (Optional)") {
            NavigationLink {
                TransactionCategoryPickerView(
                    budget: budget,
                    selectedCategoryId: $categoryId
                )
                .pickerMode(.picker)
            } label: {
                ValueLabel(text: selectedCategoryName)
            }
            .accessibilityIdentifier("EditRecurringExpenseView.CategoryField.SelectCategoryButton")
            if categoryId != nil {
                Button {
                    categoryId = nil
                } label: {
                    HStack(spacing: .paddingSmall) {
                        Image(systemName: "xmark.circle")
                        Text("Unlink Category")
                        Spacer(minLength: 0)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appMutedText)
                }
                .padding(.top, 6)
            }
        }
    }

    @ViewBuilder private func ConvertToAccountButton() -> some View {
        FieldCard(
            "Track as Account",
            footer: "Track this debt as a liability account instead — its balance counts toward your net worth, and its price becomes the monthly payment."
        ) {
            Button {
                showConvertConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "building.columns")
                        .foregroundStyle(Color.brandTeal)
                    Text("Convert to Liability Account")
                        .foregroundStyle(Color.appText)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.appMutedText)
                }
                .font(.body.weight(.semibold))
            }
            .accessibilityIdentifier("EditRecurringExpenseView.ConvertButton")
        }
    }

    @ViewBuilder private func MenuLabel(systemName: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemName)
                .foregroundStyle(Color.brandTeal)
            Text(text)
                .foregroundStyle(Color.appText)
                .contentTransition(.numericText())
            Spacer(minLength: 0)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .foregroundStyle(Color.appMutedText)
        }
        .font(.body.weight(.semibold))
    }

    @ViewBuilder private func ValueLabel(text: String) -> some View {
        HStack(spacing: 8) {
            Text(text)
                .foregroundStyle(Color.appText)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.appMutedText)
        }
        .font(.body.weight(.semibold))
    }

    @ViewBuilder private func DeleteButton() -> some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: .paddingSmall) {
                Image(systemName: "trash")
                Text("Delete Recurring Expense")
            }
            .font(.headline)
            .foregroundStyle(Color.negative)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .paddingVerticalButtonMedium)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .foregroundStyle(Color.appSurface)
            }
        }
        .accessibilityIdentifier("EditRecurringExpenseView.DeleteButton")
        .padding(.top, .paddingSmall)
    }
}

#Preview("New") {
    NavigationStack {
        EditRecurringExpenseView(budget: .previewSample())
    }
}

#Preview("Edit Debt") {
    NavigationStack {
        EditRecurringExpenseView(budget: .previewSample(recurringExpenses: RecurringExpense.samples))
            .editing(.sampleCarLoan)
    }
}

#Preview("Edit Annual Subscription") {
    NavigationStack {
        EditRecurringExpenseView(budget: .previewSample(recurringExpenses: RecurringExpense.samples))
            .editing(.sampleAnnualSubscription)
    }
}
