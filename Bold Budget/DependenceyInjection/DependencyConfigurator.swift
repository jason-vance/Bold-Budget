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
    iocContainer.autoregister(TransactionCategoryRepo.self, initializer: TransactionCategoryRepo.getInstance)
    iocContainer.autoregister(TransactionLedger.self, initializer: TransactionLedger.getInstance)
    iocContainer.autoregister(CurrentUserIdProvider.self, initializer: getCurrentUserIdProvider)
    iocContainer.autoregister(UserDataProvider.self, initializer: getUserDataProvider)
    
    // Authentication
    iocContainer.autoregister(AuthenticationProvider.self, initializer: getAuthenticationProvider)
    iocContainer.autoregister(UserSignOutService.self, initializer: getUserSignOutService)
    iocContainer.autoregister(UserAccountDeleter.self, initializer: getUserAccountDeleter)
    
    // Onboarding
    iocContainer.autoregister(UserOnboardingStateProvider.self, initializer: UserOnboardingStateProvider.init)
    iocContainer.autoregister(UsernameAvailabilityChecker.self, initializer: getUsernameAvailabilityChecker)
    iocContainer.autoregister(UserDataSaver.self, initializer: getUserDataSaver)

    // Dashboard
    iocContainer.autoregister(TransactionProvider.self, initializer: TransactionLedger.getInstance)
    
    // AddTransactions
    iocContainer.autoregister(TransactionCategorySaver.self, initializer: TransactionCategoryRepo.getInstance)
    iocContainer.autoregister(TransactionSaver.self, initializer: TransactionLedger.getInstance)
    
    // TransactionDetail
    iocContainer.autoregister(TransactionDeleter.self, initializer: TransactionLedger.getInstance)
}

fileprivate func getCurrentUserIdProvider() -> CurrentUserIdProvider {
    if let mock = MockCurrentUserIdProvider.getTestInstance() {
        return mock
    }
    return FirebaseAuthentication.instance
}

fileprivate func getUserDataProvider() -> UserDataProvider {
    if let mock = MockUserDataProvider.getTestInstance() {
        return mock
    }
    return FirebaseUserDataProvider()
}

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
