//
//  Budget.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/2/24.
//

import Foundation
import SwinjectAutoregistration
import Combine

class Budget: ObservableObject {
    
    //TODO: Since I should only have one of each item in each these collections, should I make them dicts or sets instead of arrays?
    @Published var transactions: [Transaction] = []
    @Published var transactionCategories: [Transaction.Category] = []
    
    var transactionTags: Set<Transaction.Tag> {
        transactions
            .reduce(Set<Transaction.Tag>()) { tags, transaction in tags.union(transaction.tags) }
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
    
    private func fetchData() {
        Task {
            await fetchTransactionCategories()
            await fetchTransactions()
        }
    }
    
    private func fetchTransactionCategories() async {
        do {
            transactionCategories = try await categoryFetcher.fetchTransactionCategories(in: info)
        } catch {
            print("Failed to fetch transaction categories from backend. \(error.localizedDescription)")
        }
    }
    
    private func fetchTransactions() async {
        do {
            transactions = try await transactionFetcher.fetchTransactions(in: info)
        } catch {
            print("Failed to fetch transactions from backend. \(error.localizedDescription)")
        }
    }
    
    func add(transaction: Transaction) {
        transactions = transactions + [transaction]
        Task {
            do {
                try await transactionSaver.save(transaction: transaction, to: info)
            } catch {
                print("Failed to save transaction on backend. \(error.localizedDescription)")
                transactions = transactions.filter { $0.id != transaction.id }
            }
        }
    }
    
    func remove(transaction: Transaction) {
        transactions = transactions.filter { $0.id != transaction.id }
        Task {
            do {
                try await transactionDeleter.delete(transaction: transaction, from: info)
            } catch {
                print("Failed to delete transaction on backend. \(error.localizedDescription)")
                transactions = transactions + [transaction]
            }
        }
    }
    
    func add(transactionCategory: Transaction.Category) {
        transactionCategories = transactionCategories + [transactionCategory]
        Task {
            do {
                try await categorySaver.save(category: transactionCategory, to: info)
            } catch {
                print("Failed to save transaction category on backend. \(error.localizedDescription)")
                transactionCategories = transactionCategories.filter { $0.id != transactionCategory.id }
            }
        }
    }
}
