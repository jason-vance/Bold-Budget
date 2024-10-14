//
//  Bold_BudgetApp.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/27/24.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        configureFirebase()
        setupToolbars()
        setupNavBars()
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
    
    fileprivate func setupToolbars() {
        let appearance = UIToolbarAppearance()
        appearance.backgroundColor = UIColor(Color.background)
        appearance.shadowColor = UIColor(Color.text)
        
        UIToolbar.appearance().standardAppearance = appearance
    }
    
    fileprivate func setupNavBars() {
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithOpaqueBackground()
        scrollEdgeAppearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor.init(Color.text)
        ]
        scrollEdgeAppearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor.init(Color.text)
        ]
        scrollEdgeAppearance.shadowColor = .init(Color.text.opacity(0.25))
        scrollEdgeAppearance.backgroundColor = .init(Color.background)
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
        
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithOpaqueBackground()
        standardAppearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor.init(Color.text)
        ]
        standardAppearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor : UIColor.init(Color.text)
        ]
        standardAppearance.shadowColor = .init(Color.text.opacity(0.25))
        standardAppearance.backgroundColor = .init(Color.background)
        UINavigationBar.appearance().standardAppearance = standardAppearance
    }
}

@main
struct Bold_BudgetApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
