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
    
    var popupNotificationCenter: PopupNotificationCenter? {
        iocContainer.resolve(PopupNotificationCenter.self)
    }
    
    let budgetRenamer: BudgetRenamer

    let transactionFetcher: TransactionFetcher
    let transactionSaver: TransactionSaver
    let transactionDeleter: TransactionDeleter
    
    let categoryFetcher: TransactionCategoryFetcher
    let categorySaver: TransactionCategorySaver

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
            categorySaver: iocContainer~>TransactionCategorySaver.self
        )
    }
    
    init(
        info: BudgetInfo,
        budgetRenamer: BudgetRenamer,
        transactionFetcher: TransactionFetcher,
        transactionSaver: TransactionSaver,
        transactionDeleter: TransactionDeleter,
        categoryFetcher: TransactionCategoryFetcher,
        categorySaver: TransactionCategorySaver
    ) {
        self.id = info.id
        self.info = info
        self.budgetRenamer = budgetRenamer
        self.transactionFetcher = transactionFetcher
        self.transactionSaver = transactionSaver
        self.transactionDeleter = transactionDeleter
        self.categoryFetcher = categoryFetcher
        self.categorySaver = categorySaver

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
    
    func getCategoryBy(id: Transaction.Category.Id) -> Transaction.Category {
        transactionCategories[id] ?? .unknown
    }
    
    func description(of transaction: Transaction) -> String {
        transaction.title?.value ?? getCategoryBy(id: transaction.categoryId).name.value
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
