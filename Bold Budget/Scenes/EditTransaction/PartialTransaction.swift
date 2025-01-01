//
//  PartialTransaction.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/31/24.
//

import Foundation

struct PartialTransaction {
    let title: Transaction.Title?
    let amount: Money?
    let categoryId: Transaction.Category.Id?
    let location: Transaction.Location?
    let tags: Set<Transaction.Tag>
}

extension PartialTransaction: Equatable { }
