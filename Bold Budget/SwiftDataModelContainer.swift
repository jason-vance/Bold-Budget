//
//  SwiftDataModelContainer.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/8/24.
//

import Foundation
import SwiftData

let sharedModelContainer: ModelContainer = {
    ValueTransformer.setValueTransformer(MoneyValueTransformer(), forName: MoneyValueTransformer.name)
    ValueTransformer.setValueTransformer(SimpleDateValueTransformer(), forName: SimpleDateValueTransformer.name)

    ValueTransformer.setValueTransformer(TransactionTitleValueTransformer(), forName: TransactionTitleValueTransformer.name)
    ValueTransformer.setValueTransformer(TransactionLocationValueTransformer(), forName: TransactionLocationValueTransformer.name)

    ValueTransformer.setValueTransformer(TransactionCategoryNameValueTransformer(), forName: TransactionCategoryNameValueTransformer.name)
    ValueTransformer.setValueTransformer(TransactionCategorySfSymbolValueTransformer(), forName: TransactionCategorySfSymbolValueTransformer.name)

    let schema = Schema([
        Transaction.self,
        Transaction.Category.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
