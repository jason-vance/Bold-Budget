//
//  TransactionCategoryFetcher.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/26/24.
//

import Foundation

protocol TransactionCategoryFetcher {
    func fetchTransactionCategories(in budget: BudgetInfo) async throws -> [Transaction.Category]
}
