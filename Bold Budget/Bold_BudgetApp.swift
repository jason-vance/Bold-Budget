//
//  Bold_BudgetApp.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/27/24.
//

import SwiftData
import SwiftUI

let sharedModelContainer: ModelContainer = {
    ValueTransformer.setValueTransformer(TransactionCategoryNameValueTransformer(), forName: TransactionCategoryNameValueTransformer.name)
    ValueTransformer.setValueTransformer(TransactionCategorySfSymbolValueTransformer(), forName: TransactionCategorySfSymbolValueTransformer.name)

    let schema = Schema([
        Transaction.Category.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        setup(iocContainer: iocContainer)
        return true
    }
}

@main
struct Bold_BudgetApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
    }
}
