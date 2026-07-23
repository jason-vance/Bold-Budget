//
//  BudgetNavigator.swift
//  Bold Budget
//
//  Created by Claude on 7/23/26.
//
//  Drives the root budget navigation stack. Budget detail screens are pushed as `BudgetInfo`
//  values on `path`, which lets any descendant (e.g. the settings screen's budget switcher) replace
//  the currently shown budget by resetting the path.
//

import SwiftUI

@MainActor
final class BudgetNavigator: ObservableObject {

    @Published var path: [BudgetInfo] = []

    /// Switches the app to show the given budget, replacing whatever budget (and its sub-screens)
    /// is currently on the stack.
    func open(_ budget: BudgetInfo) {
        path = [budget]
    }
}
