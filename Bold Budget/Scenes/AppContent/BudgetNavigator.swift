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

    /// Switches the app to show the given budget's detail screen.
    ///
    /// Resetting the path in a single assignment doesn't reliably switch budgets: when view-based
    /// screens (settings, pickers) are pushed on top of the budget detail, SwiftUI pops those but
    /// keeps the existing detail rather than rebuilding it for the new budget — so the newly
    /// selected budget never renders. Fully pop to the root, then push the new budget on the next
    /// runloop tick so SwiftUI processes two distinct updates and rebuilds the detail. Animations
    /// are suppressed so the root list doesn't flash during the hop.
    func open(_ budget: BudgetInfo) {
        var transaction = SwiftUI.Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) { path = [] }
        DispatchQueue.main.async {
            withTransaction(transaction) { self.path = [budget] }
        }
    }
}
