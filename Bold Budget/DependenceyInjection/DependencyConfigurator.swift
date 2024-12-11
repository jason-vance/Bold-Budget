//
//  DependencyConfigurator.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation
import Swinject
import SwinjectAutoregistration

func setup(iocContainer: Container) {
    // Misc
    iocContainer.autoregister(CurrentUserIdProvider.self, initializer: getCurrentUserIdProvider)
    iocContainer.autoregister(CurrentUserDataProvider.self, initializer: getCurrentUserDataProvider)
    iocContainer.autoregister(UserDataProvider.self, initializer: getUserDataProvider)
    iocContainer.autoregister(UserDataFetcher.self, initializer: getUserDataFetcher)
    iocContainer.autoregister(SubscriptionLevelProvider.self, initializer: { StoreKitSubscriptionLevelProvider.instance })
    
    // Authentication
    iocContainer.autoregister(AuthenticationProvider.self, initializer: getAuthenticationProvider)
    iocContainer.autoregister(UserSignOutService.self, initializer: getUserSignOutService)
    iocContainer.autoregister(UserAccountDeleter.self, initializer: getUserAccountDeleter)
    
    // UserProfile
    iocContainer.autoregister(UsernameAvailabilityChecker.self, initializer: getUsernameAvailabilityChecker)
    iocContainer.autoregister(UserDataSaver.self, initializer: getUserDataSaver)
    iocContainer.autoregister(ProfileImageUploader.self, initializer: getProfileImageUploader)
    
    // Onboarding
    iocContainer.autoregister(UserOnboardingStateProvider.self, initializer: UserOnboardingStateProvider.init)
    
    // Budgets
    registerBudgetCreator()
    registerBudgetFetcher()

    // TransactionCategories
    registerTransactionCategoryFetcher()
    registerTransactionCategorySaver()
    
    // Transactions
    registerTransactionFetcher()
    registerTransactionSaver()
    registerTransactionDeleter()
}

//MARK: Misc

fileprivate func getCurrentUserIdProvider() -> CurrentUserIdProvider {
    if let mock = MockCurrentUserIdProvider.getTestInstance() {
        return mock
    }
    return FirebaseAuthentication.instance
}

fileprivate func getCurrentUserDataProvider() -> CurrentUserDataProvider {
    if let mock = MockCurrentUserDataProvider.getTestInstance() {
        return mock
    }
    return FirebaseCurrentUserDataProvider.instance
}

fileprivate func getUserDataProvider() -> UserDataProvider {
    if let mock = MockUserDataProvider.getTestInstance() {
        return mock
    }
    return FirebaseUserDataProvider()
}

fileprivate func getUserDataFetcher() -> UserDataFetcher {
    if let mock = MockUserDataFetcher.getTestInstance() {
        return mock
    }
    return FirebaseUserRepository()
}

//MARK: Authentication

fileprivate func getAuthenticationProvider() -> AuthenticationProvider {
    if let mock = MockAuthenticationProvider.getTestInstance() {
        return mock
    }
    return FirebaseAuthentication.instance
}

fileprivate func getUserSignOutService() -> UserSignOutService {
    return FirebaseAuthentication.instance
}

fileprivate func getUserAccountDeleter() -> UserAccountDeleter {
    return FirebaseAuthentication.instance
}

//MARK: UserProfile

fileprivate func getUsernameAvailabilityChecker() -> UsernameAvailabilityChecker {
    if let mock = MockUsernameAvailabilityChecker.getTestInstance() {
        return mock
    }
    return FirebaseUserRepository()
}

fileprivate func getUserDataSaver() -> UserDataSaver {
    if let mock = MockUserDataSaver.getTestInstance() {
        return mock
    }
    return FirebaseUserRepository()
}

fileprivate func getProfileImageUploader() -> ProfileImageUploader {
    if let mock = MockProfileImageUploader.getTestInstance() {
        return mock
    }
    return FirebaseProfileImageStorage()
}

//MARK: Budgets

fileprivate func registerBudgetCreator() {
    var service: BudgetCreator = FirebaseBudgetRepository()
    if let mock = MockBudgetSaver.getTestInstance() {
        service = mock
    }
    iocContainer.autoregister(BudgetCreator.self, initializer: { service })
}

fileprivate func registerBudgetFetcher() {
    var service: BudgetFetcher = FirebaseBudgetRepository()
    if let mock = MockBudgetFetcher.getTestInstance() {
        service = mock
    }
    iocContainer.autoregister(BudgetFetcher.self, initializer: { service })
}

//MARK: TransactionCategories

fileprivate func registerTransactionCategoryFetcher() {
    var service: TransactionCategoryFetcher = FirebaseTransactionCategoryRepository()
    if let mock = MockTransactionCategoryRepo.getTestInstance() {
        service = mock
    }

    iocContainer.autoregister(TransactionCategoryFetcher.self, initializer: { service })
}

fileprivate func registerTransactionCategorySaver() {
    var service: TransactionCategorySaver = FirebaseTransactionCategoryRepository()
    if let mock = MockTransactionCategoryRepo.getTestInstance() {
        service = mock
    }

    iocContainer.autoregister(TransactionCategorySaver.self, initializer: { service })
}

//MARK: Transactions

fileprivate func registerTransactionFetcher() {
    var service: TransactionFetcher = FirebaseTransactionRepository()
    if let mock = MockTransactionFetcher.getTestInstance() {
        service = mock
    }
    iocContainer.autoregister(TransactionFetcher.self, initializer: { service })
}

fileprivate func registerTransactionSaver() {
    var service: TransactionSaver = FirebaseTransactionRepository()
    if let mock = MockTransactionSaver.getTestInstance() {
        service = mock
    }
    iocContainer.autoregister(TransactionSaver.self, initializer: { service })
}

fileprivate func registerTransactionDeleter() {
    var service: TransactionDeleter = FirebaseTransactionRepository()
    if let mock = MockTransactionDeleter.getTestInstance() {
        service = mock
    }
    iocContainer.autoregister(TransactionDeleter.self, initializer: { service })
}
