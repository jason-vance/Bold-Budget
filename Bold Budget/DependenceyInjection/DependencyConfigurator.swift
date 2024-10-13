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
    
    // Authentication
    iocContainer.autoregister(AuthenticationProvider.self, initializer: getAuthenticationProvider)
    iocContainer.autoregister(UserSignOutService.self, initializer: getUserSignOutService)

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

fileprivate func getAuthenticationProvider() -> AuthenticationProvider {
    if let mock = MockAuthenticationProvider.getTestInstance() {
        return mock
    }
    return FirebaseAuthentication.instance
}

fileprivate func getUserSignOutService() -> UserSignOutService {
    return FirebaseAuthentication.instance
}
