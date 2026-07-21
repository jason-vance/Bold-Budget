//
//  FirebaseAccountRepository.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/21/26.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseAccountRepository {

    static let ACCOUNTS = "Accounts"

    func accountsCollection(in budget: BudgetInfo) -> CollectionReference {
        Firestore.firestore()
            .collection(FirebaseBudgetRepository.BUDGETS)
            .document(budget.id)
            .collection(Self.ACCOUNTS)
    }
}

extension FirebaseAccountRepository: AccountFetcher {
    func fetchAccounts(in budget: BudgetInfo) async throws -> [Account] {
        try await accountsCollection(in: budget)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: FirebaseAccountDoc.self).toAccount() }
    }
}

extension FirebaseAccountRepository: AccountSaver {
    func save(account: Account, to budget: BudgetInfo) async throws {
        let doc = FirebaseAccountDoc.from(account)
        try await accountsCollection(in: budget)
            .document(account.id.uuidString)
            .setData(from: doc)
    }
}

extension FirebaseAccountRepository: AccountDeleter {
    func delete(account: Account, from budget: BudgetInfo) async throws {
        try await accountsCollection(in: budget)
            .document(account.id.uuidString)
            .delete()
    }
}
