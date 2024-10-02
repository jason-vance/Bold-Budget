//
//  TransactionProvider.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import Foundation
import Combine

protocol TransactionProvider {
    var transactionPublisher: AnyPublisher<[Transaction],Never> { get }
}
