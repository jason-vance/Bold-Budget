//
//  FirebaseRecurringExpenseRepository.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/15/26.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseRecurringExpenseRepository {

    static let RECURRING_EXPENSES = "RecurringExpenses"

    func recurringExpensesCollection(in budget: BudgetInfo) -> CollectionReference {
        Firestore.firestore()
            .collection(FirebaseBudgetRepository.BUDGETS)
            .document(budget.id)
            .collection(Self.RECURRING_EXPENSES)
    }
}

extension FirebaseRecurringExpenseRepository: RecurringExpenseFetcher {
    func fetchRecurringExpenses(in budget: BudgetInfo) async throws -> [RecurringExpense] {
        try await recurringExpensesCollection(in: budget)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: FirebaseRecurringExpenseDoc.self).toRecurringExpense() }
    }
}

extension FirebaseRecurringExpenseRepository: RecurringExpenseSaver {
    func save(recurringExpense: RecurringExpense, to budget: BudgetInfo) async throws {
        let doc = FirebaseRecurringExpenseDoc.from(recurringExpense)
        try await recurringExpensesCollection(in: budget)
            .document(recurringExpense.id.uuidString)
            .setData(from: doc)
    }
}

extension FirebaseRecurringExpenseRepository: RecurringExpenseDeleter {
    func delete(recurringExpense: RecurringExpense, from budget: BudgetInfo) async throws {
        try await recurringExpensesCollection(in: budget)
            .document(recurringExpense.id.uuidString)
            .delete()
    }
}
