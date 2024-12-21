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
    
    @Published var isLoading: Bool = false
    @Published var transactions: [Transaction.Id:Transaction] = [:]
    @Published var transactionCategories: [Transaction.Category.Id:Transaction.Category] = [:]
    
    var transactionTags: Set<Transaction.Tag> {
        transactions
            .reduce(Set<Transaction.Tag>()) { tags, transaction in tags.union(transaction.value.tags) }
    }

    let info: BudgetInfo
    
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
            transactionFetcher: iocContainer~>TransactionFetcher.self,
            transactionSaver: iocContainer~>TransactionSaver.self,
            transactionDeleter: iocContainer~>TransactionDeleter.self,
            categoryFetcher: iocContainer~>TransactionCategoryFetcher.self,
            categorySaver: iocContainer~>TransactionCategorySaver.self
        )
    }
    
    init(
        info: BudgetInfo,
        transactionFetcher: TransactionFetcher,
        transactionSaver: TransactionSaver,
        transactionDeleter: TransactionDeleter,
        categoryFetcher: TransactionCategoryFetcher,
        categorySaver: TransactionCategorySaver
    ) {
        self.info = info
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
            print("Failed to fetch transaction categories from backend. \(error.localizedDescription)")
        }
    }
    
    private func fetchTransactions() async {
        do {
            let transactions = try await transactionFetcher.fetchTransactions(in: info)
            self.transactions = Dictionary(uniqueKeysWithValues: transactions.map { ($0.id, $0) })
        } catch {
            print("Failed to fetch transactions from backend. \(error.localizedDescription)")
        }
    }
    
    func save(transaction: Transaction) {
        let tmp = transactions.updateValue(transaction, forKey: transaction.id)
        Task {
            do {
                try await transactionSaver.save(transaction: transaction, to: info)
            } catch {
                print("Failed to save transaction on backend. \(error.localizedDescription)")
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
                print("Failed to delete transaction on backend. \(error.localizedDescription)")
                transactions[transaction.id] = tmp
            }
        }
    }
    
    func add(transactionCategory: Transaction.Category) {
        let tmp = transactionCategories.updateValue(transactionCategory, forKey: transactionCategory.id)
        Task {
            do {
                try await categorySaver.save(category: transactionCategory, to: info)
            } catch {
                print("Failed to save transaction category on backend. \(error.localizedDescription)")
                transactionCategories[transactionCategory.id] = tmp
            }
        }
    }
}
