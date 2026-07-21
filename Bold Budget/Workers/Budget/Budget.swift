//
//  Budget.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/2/24.
//

import Foundation
import SwinjectAutoregistration
import Combine

@MainActor
class Budget: ObservableObject {
    
    let id: String
    
    @Published var isLoading: Bool = false
    @Published var info: BudgetInfo {
        willSet {
            if id != info.id {
                assertionFailure("Budget ids don't match")
            }
        }
    }
    @Published var transactions: [Transaction.Id:Transaction] = [:]
    @Published var transactionCategories: [Transaction.Category.Id:Transaction.Category] = [:]
    @Published var recurringExpenses: [RecurringExpense.Id:RecurringExpense] = [:]
    @Published var accounts: [Account.Id:Account] = [:]
    
    var transactionTags: Set<Transaction.Tag> {
        transactions
            .map { $0.value }
            .map(\.tags)
            .reduce(into: Set()) { $0 = $0.union($1) }
    }
    
    var transactionTitles: Set<Transaction.Title> {
        transactions
            .map { $0.value }
            .compactMap(\.title)
            .reduce(into: Set()) { $0.insert($1) }
    }
    
    var transactionLocations: Set<Transaction.Location> {
        transactions
            .map { $0.value }
            .compactMap(\.location)
            .reduce(into: Set()) { $0.insert($1) }
    }
    
    var transactionAmounts: Set<Money> {
        transactions
            .map { $0.value }
            .compactMap(\.amount)
            .reduce(into: Set()) { $0.insert($1) }
    }
    
    var transactionsByCategory: [Transaction.Category:[Transaction]] {
        transactions.reduce(into: [:]) { result, transaction in
            let category = getCategoryBy(id: transaction.value.categoryId)
            result[category, default: []].append(transaction.value)
        }
    }

    var assetAccounts: [Account] { Array(accounts.values).assets }
    var liabilityAccounts: [Account] { Array(accounts.values).liabilities }

    var totalAssets: Money { Array(accounts.values).totalAssets }
    var totalLiabilities: Money { Array(accounts.values).totalLiabilities }

    /// Assets minus liabilities across all accounts. May be negative.
    var netWorth: SignedMoney { Array(accounts.values).netWorth }
    
    var popupNotificationCenter: PopupNotificationCenter? {
        iocContainer.resolve(PopupNotificationCenter.self)
    }
    
    let budgetRenamer: BudgetRenamer

    let transactionFetcher: TransactionFetcher
    let transactionSaver: TransactionSaver
    let transactionDeleter: TransactionDeleter
    
    let categoryFetcher: TransactionCategoryFetcher
    let categorySaver: TransactionCategorySaver
    let categoryDeleter: TransactionCategoryDeleter

    let recurringExpenseFetcher: RecurringExpenseFetcher
    let recurringExpenseSaver: RecurringExpenseSaver
    let recurringExpenseDeleter: RecurringExpenseDeleter

    let accountFetcher: AccountFetcher
    let accountSaver: AccountSaver
    let accountDeleter: AccountDeleter

    convenience init(
        info: BudgetInfo
    ) {
        self.init(
            info: info,
            budgetRenamer: iocContainer~>BudgetRenamer.self,
            transactionFetcher: iocContainer~>TransactionFetcher.self,
            transactionSaver: iocContainer~>TransactionSaver.self,
            transactionDeleter: iocContainer~>TransactionDeleter.self,
            categoryFetcher: iocContainer~>TransactionCategoryFetcher.self,
            categorySaver: iocContainer~>TransactionCategorySaver.self,
            categoryDeleter: iocContainer~>TransactionCategoryDeleter.self,
            recurringExpenseFetcher: iocContainer~>RecurringExpenseFetcher.self,
            recurringExpenseSaver: iocContainer~>RecurringExpenseSaver.self,
            recurringExpenseDeleter: iocContainer~>RecurringExpenseDeleter.self,
            accountFetcher: iocContainer~>AccountFetcher.self,
            accountSaver: iocContainer~>AccountSaver.self,
            accountDeleter: iocContainer~>AccountDeleter.self
        )
    }

    init(
        info: BudgetInfo,
        budgetRenamer: BudgetRenamer,
        transactionFetcher: TransactionFetcher,
        transactionSaver: TransactionSaver,
        transactionDeleter: TransactionDeleter,
        categoryFetcher: TransactionCategoryFetcher,
        categorySaver: TransactionCategorySaver,
        categoryDeleter: TransactionCategoryDeleter,
        recurringExpenseFetcher: RecurringExpenseFetcher,
        recurringExpenseSaver: RecurringExpenseSaver,
        recurringExpenseDeleter: RecurringExpenseDeleter,
        accountFetcher: AccountFetcher,
        accountSaver: AccountSaver,
        accountDeleter: AccountDeleter
    ) {
        self.id = info.id
        self.info = info
        self.budgetRenamer = budgetRenamer
        self.transactionFetcher = transactionFetcher
        self.transactionSaver = transactionSaver
        self.transactionDeleter = transactionDeleter
        self.categoryFetcher = categoryFetcher
        self.categorySaver = categorySaver
        self.categoryDeleter = categoryDeleter
        self.recurringExpenseFetcher = recurringExpenseFetcher
        self.recurringExpenseSaver = recurringExpenseSaver
        self.recurringExpenseDeleter = recurringExpenseDeleter
        self.accountFetcher = accountFetcher
        self.accountSaver = accountSaver
        self.accountDeleter = accountDeleter

        fetchData()
    }
    
    public func refresh() {
        fetchData()
    }
    
    private func fetchData() {
        isLoading = true
        let isLoading_False = { self.isLoading = false }
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await self.fetchTransactionCategories()
                }
                group.addTask {
                    await self.fetchTransactions()
                }
                group.addTask {
                    await self.fetchRecurringExpenses()
                }
                group.addTask {
                    await self.fetchAccounts()
                }
            }

            RunLoop.main.perform { isLoading_False() }
        }
    }
    
    private func fetchTransactionCategories() async {
        do {
            let categories = try await categoryFetcher.fetchTransactionCategories(in: info)
            transactionCategories = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        } catch {
            onError("Failed to fetch transaction categories.", error: error)
        }
    }
    
    private func fetchTransactions() async {
        do {
            let transactions = try await transactionFetcher.fetchTransactions(in: info)
            self.transactions = Dictionary(uniqueKeysWithValues: transactions.map { ($0.id, $0) })
        } catch {
            onError("Failed to fetch transactions.", error: error)
        }
    }
    
    private func fetchRecurringExpenses() async {
        do {
            let recurringExpenses = try await recurringExpenseFetcher.fetchRecurringExpenses(in: info)
            self.recurringExpenses = Dictionary(uniqueKeysWithValues: recurringExpenses.map { ($0.id, $0) })
        } catch {
            onError("Failed to fetch recurring expenses.", error: error)
        }
    }

    private func fetchAccounts() async {
        do {
            let accounts = try await accountFetcher.fetchAccounts(in: info)
            self.accounts = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0) })
        } catch {
            onError("Failed to fetch accounts.", error: error)
        }
    }

    func save(transaction: Transaction) {
        let tmp = transactions.updateValue(transaction, forKey: transaction.id)
        Task {
            do {
                try await transactionSaver.save(transaction: transaction, to: info)
            } catch {
                onError("Failed to save transaction.", error: error)

                transactions[transaction.id] = tmp
            }
        }
    }
    
    func remove(transaction: Transaction) {
        let tmp = transactions.removeValue(forKey: transaction.id)
        Task {
            do {
                try await transactionDeleter.delete(transaction: transaction, from: info)
            } catch {
                onError("Failed to delete transaction.", error: error)

                transactions[transaction.id] = tmp
            }
        }
    }
    
    func save(recurringExpense: RecurringExpense) {
        let tmp = recurringExpenses.updateValue(recurringExpense, forKey: recurringExpense.id)
        Task {
            do {
                try await recurringExpenseSaver.save(recurringExpense: recurringExpense, to: info)
            } catch {
                onError("Failed to save recurring expense.", error: error)

                recurringExpenses[recurringExpense.id] = tmp
            }
        }
    }

    func remove(recurringExpense: RecurringExpense) {
        let tmp = recurringExpenses.removeValue(forKey: recurringExpense.id)
        Task {
            do {
                try await recurringExpenseDeleter.delete(recurringExpense: recurringExpense, from: info)
            } catch {
                onError("Failed to delete recurring expense.", error: error)

                recurringExpenses[recurringExpense.id] = tmp
            }
        }
    }

    func save(account: Account) {
        let tmp = accounts.updateValue(account, forKey: account.id)
        Task {
            do {
                try await accountSaver.save(account: account, to: info)
            } catch {
                onError("Failed to save account.", error: error)

                accounts[account.id] = tmp
            }
        }
    }

    func remove(account: Account) {
        let tmp = accounts.removeValue(forKey: account.id)
        Task {
            do {
                try await accountDeleter.delete(account: account, from: info)
            } catch {
                onError("Failed to delete account.", error: error)

                accounts[account.id] = tmp
            }
        }
    }

    func save(transactionCategory: Transaction.Category) {
        let tmp = transactionCategories.updateValue(transactionCategory, forKey: transactionCategory.id)
        Task {
            do {
                try await categorySaver.save(category: transactionCategory, to: info)
            } catch {
                onError("Failed to save transaction category.", error: error)

                transactionCategories[transactionCategory.id] = tmp
            }
        }
    }

    func remove(transactionCategory category: Transaction.Category,
                replacingWith replacement: Transaction.Category?) {
        let affected = transactions.values.filter { $0.categoryId == category.id }

        if !affected.isEmpty && replacement == nil { return }

        let removedCategory = transactionCategories.removeValue(forKey: category.id)
        let originals = affected

        if let replacement {
            for txn in affected {
                transactions[txn.id] = txn.with(categoryId: replacement.id)
            }
        }

        Task {
            do {
                if let replacement {
                    for txn in affected {
                        let updated = txn.with(categoryId: replacement.id)
                        try await transactionSaver.save(transaction: updated, to: info)
                    }
                }
                try await categoryDeleter.delete(category: category, from: info)
            } catch {
                onError("Failed to delete transaction category.", error: error)

                if let removedCategory { transactionCategories[removedCategory.id] = removedCategory }
                for txn in originals { transactions[txn.id] = txn }
            }
        }
    }
    
    func getCategoryBy(id: Transaction.Category.Id) -> Transaction.Category {
        transactionCategories[id] ?? .unknown
    }
    
    func description(of transaction: Transaction) -> String {
        transaction.title?.value ?? getCategoryBy(id: transaction.categoryId).name.value
    }
    
    func amountString(for transaction: Transaction) -> String {
        let isIncome = getCategoryBy(id: transaction.categoryId).kind == .income
        return (isIncome ? "+" : "") + transaction.amount.formatted()
    }
    
    func set(name: BudgetInfo.Name) {
        let prevInfo = info
        info = .init(id: info.id, name: name, users: info.users)
        Task {
            do {
                try await budgetRenamer.rename(budget: self, to: name)
            } catch {
                onError("Failed to rename budget.", error: error)

                info = prevInfo
            }
        }
    }
    
    private func onError(_ message: String, error: Error) {
        print("\(message) \(error.localizedDescription)")
        if let popupNotificationCenter = popupNotificationCenter {
            popupNotificationCenter.errorNotification(message, error: error)
        }
    }
}

extension Budget: Equatable {
    nonisolated public static func == (lhs: Budget, rhs: Budget) -> Bool {
        lhs.id == rhs.id
    }
}

extension Budget {
    /// A Budget backed entirely by mocks, pre-populated with sample data, for SwiftUI previews.
    static func previewSample(
        transactions: [Transaction] = [],
        recurringExpenses: [RecurringExpense] = [],
        accounts: [Account] = []
    ) -> Budget {
        let transactionFetcher = MockTransactionFetcher()
        transactionFetcher.transactions = transactions

        let recurringExpenseFetcher = MockRecurringExpenseFetcher()
        recurringExpenseFetcher.recurringExpenses = recurringExpenses

        let accountFetcher = MockAccountFetcher()
        accountFetcher.accounts = accounts

        let categoryRepo = MockTransactionCategoryRepo(initialCategories: Transaction.Category.samples)

        return Budget(
            info: .sample,
            budgetRenamer: MockBudgetRenamer(),
            transactionFetcher: transactionFetcher,
            transactionSaver: MockTransactionSaver(),
            transactionDeleter: MockTransactionDeleter(),
            categoryFetcher: categoryRepo,
            categorySaver: categoryRepo,
            categoryDeleter: categoryRepo,
            recurringExpenseFetcher: recurringExpenseFetcher,
            recurringExpenseSaver: MockRecurringExpenseSaver(),
            recurringExpenseDeleter: MockRecurringExpenseDeleter(),
            accountFetcher: accountFetcher,
            accountSaver: MockAccountSaver(),
            accountDeleter: MockAccountDeleter()
        )
    }
}
