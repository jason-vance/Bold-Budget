//
//  Bold_BudgetApp.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/27/24.
//

import SwiftUI
import SwiftData
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        configureFirebase()
        setup(iocContainer: iocContainer)
        return true
    }
    
    private func configureFirebase() {
#if DEBUG
        let fileName = "GoogleService-Info-Dev"
#else
        let fileName = "GoogleService-Info"
#endif
        print("Firebase fileName: \(fileName)")
        
        if let path = Bundle.main.path(forResource:fileName, ofType:"plist") {
            FirebaseApp.configure(options: .init(contentsOfFile: path)!)
        }
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
