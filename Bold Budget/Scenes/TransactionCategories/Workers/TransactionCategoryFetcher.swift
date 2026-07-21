//
//  TransactionCategoryFetcher.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/26/24.
//

import Foundation

protocol TransactionCategoryFetcher {
    func fetchTransactionCategories(in budget: BudgetInfo) async throws -> [Transaction.Category]

    /// Legacy income/expense kinds still stored on category documents, keyed by category id.
    /// Used once to backfill `Transaction.kind` on rows that predate transaction-level kinds;
    /// categories themselves are no longer income/expense-typed.
    func fetchLegacyCategoryKinds(in budget: BudgetInfo) async throws -> [Transaction.Category.Id: Transaction.Kind]
}
