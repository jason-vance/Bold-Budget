//
//  BalanceSnapshot.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/21/26.
//

import Foundation

/// A recorded account balance at a point in time — one cell of the old retirement spreadsheet.
struct BalanceSnapshot: Identifiable {

    let date: SimpleDate
    let value: Money

    var id: SimpleDate.RawValue { date.rawValue }
}

extension BalanceSnapshot: Equatable {}
extension BalanceSnapshot: Hashable {}
