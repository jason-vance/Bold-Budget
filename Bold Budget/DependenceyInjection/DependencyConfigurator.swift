//
//  DependencyConfigurator.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import Foundation
import Swinject
import SwinjectAutoregistration

let iocContainer: Container = Container()

func setup(iocContainer: Container) {
    iocContainer.autoregister(StringProvider.self, initializer: StringProvider.getInstance)
    
    iocContainer.autoregister(TransactionCategoryRepo.self, initializer: TransactionCategoryRepo.getInstance)
    iocContainer.autoregister(TransactionLedger.self, initializer: TransactionLedger.getInstance)
    
    // Dashboard
    iocContainer.autoregister(TransactionProvider.self, initializer: TransactionLedger.getInstance)
    
    // AddTransactions
    iocContainer.autoregister(TransactionCategorySaver.self, initializer: TransactionCategoryRepo.getInstance)
}
