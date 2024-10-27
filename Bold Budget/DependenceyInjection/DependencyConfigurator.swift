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
    iocContainer.autoregister(TransactionTagProvider.self, initializer: TransactionLedger.getInstance)
    iocContainer.autoregister(TransactionLedger.self, initializer: TransactionLedger.getInstance)
    iocContainer.autoregister(CurrentUserIdProvider.self, initializer: getCurrentUserIdProvider)
    iocContainer.autoregister(CurrentUserDataProvider.self, initializer: getCurrentUserDataProvider)
    iocContainer.autoregister(UserDataProvider.self, initializer: getUserDataProvider)
    iocContainer.autoregister(UserDataFetcher.self, initializer: getUserDataFetcher)
    
    // Budgets
    iocContainer.autoregister(BudgetsListBudgetsProvider.self, initializer: BudgetsListBudgetsProvider.init)
    
    // TransactionCategories
    registerTransactionCategoryFetcher(in: iocContainer)
    registerTransactionCategorySaver(in: iocContainer)

    // Authentication
    iocContainer.autoregister(AuthenticationProvider.self, initializer: getAuthenticationProvider)
    iocContainer.autoregister(UserSignOutService.self, initializer: getUserSignOutService)
    iocContainer.autoregister(UserAccountDeleter.self, initializer: getUserAccountDeleter)

    // Onboarding
    iocContainer.autoregister(UserOnboardingStateProvider.self, initializer: UserOnboardingStateProvider.init)
    
    // Dashboard
    iocContainer.autoregister(BudgetsProvider.self, initializer: getBudgetsProvider)
    iocContainer.autoregister(TransactionProvider.self, initializer: TransactionLedger.getInstance)
    
    // AddBudget
    iocContainer.autoregister(BudgetSaver.self, initializer: getBudgetSaver)

    // AddTransactions
    iocContainer.autoregister(TransactionSaver.self, initializer: TransactionLedger.getInstance)
    
    // TransactionDetail
    iocContainer.autoregister(TransactionDeleter.self, initializer: TransactionLedger.getInstance)
    
    // UserProfile
    iocContainer.autoregister(UsernameAvailabilityChecker.self, initializer: getUsernameAvailabilityChecker)
    iocContainer.autoregister(UserDataSaver.self, initializer: getUserDataSaver)
    iocContainer.autoregister(ProfileImageUploader.self, initializer: getProfileImageUploader)
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

//MARK: Budgets

fileprivate func getBudgetSaver() -> BudgetSaver {
    if let mock = MockBudgetSaver.getTestInstance() {
        return mock
    }
    return FirebaseBudgetsRepository()
}

//MARK: TransactionCategories

//TODO: Change all of these to single instances if appropriate, like the following

fileprivate func registerTransactionCategoryFetcher(in: Container) {
    var service: TransactionCategoryFetcher = FirebaseTransactionCategoryRepository()
    if let mock = MockTransactionCategoryRepo.getTestInstance() {
        service = mock
    }

    iocContainer.autoregister(TransactionCategoryFetcher.self, initializer: { service })
}

fileprivate func registerTransactionCategorySaver(in: Container) {
    var service: TransactionCategorySaver = FirebaseTransactionCategoryRepository()
    if let mock = MockTransactionCategoryRepo.getTestInstance() {
        service = mock
    }

    iocContainer.autoregister(TransactionCategorySaver.self, initializer: { service })
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

//MARK: Dashboard

fileprivate func getBudgetsProvider() -> BudgetsProvider {
    if let mock = MockBudgetsProvider.getTestInstance() {
        return mock
    }
    return FirebaseBudgetsProvider()
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
