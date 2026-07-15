//
//  RecurringExpenseTests.swift
//  Bold BudgetTests
//
//  Created by Jason Vance on 7/15/26.
//

import Testing
import Foundation

struct RecurringExpenseTests {

    @Test func monthlyCostOfMonthlyExpenseIsItsPrice() {
        let rent = RecurringExpense(
            id: RecurringExpense.Id(),
            name: .init("Rent")!,
            kind: .bill,
            price: Money(3400)!
        )

        #expect(rent.monthlyCost == Money(3400)!)
    }

    @Test func monthlyCostOfAnnualExpenseIsPriceDividedByTwelve() {
        let appleDeveloper = RecurringExpense(
            id: RecurringExpense.Id(),
            name: .init("Apple Developer")!,
            kind: .subscription,
            price: Money(99)!,
            monthsPerCycle: 12
        )

        #expect(appleDeveloper.monthlyCost == Money(8.25)!)
    }

    @Test func monthsPerCycleIsClampedToAtLeastOne() {
        let expense = RecurringExpense(
            id: RecurringExpense.Id(),
            name: .init("Bad Cycle")!,
            kind: .subscription,
            price: Money(10)!,
            monthsPerCycle: 0
        )

        #expect(expense.monthsPerCycle == 1)
        #expect(expense.monthlyCost == Money(10)!)
    }

    @Test func totalMonthlyCostSumsNormalizedCosts() {
        let expenses: [RecurringExpense] = [
            .init(id: RecurringExpense.Id(), name: .init("Rent")!, kind: .bill, price: Money(3400)!),
            .init(id: RecurringExpense.Id(), name: .init("Annual")!, kind: .subscription, price: Money(120)!, monthsPerCycle: 12),
        ]

        #expect(expenses.totalMonthlyCost == Money(3410)!)
    }

    @Test func totalRemainingBalanceSumsOnlyExpensesWithBalances() {
        let expenses: [RecurringExpense] = [
            .init(id: RecurringExpense.Id(), name: .init("Pilot")!, kind: .debt, price: Money(548)!, remainingBalance: Money(17810)!),
            .init(id: RecurringExpense.Id(), name: .init("CX-30")!, kind: .debt, price: Money(458)!, remainingBalance: Money(28179)!),
            .init(id: RecurringExpense.Id(), name: .init("Rent")!, kind: .bill, price: Money(3400)!),
        ]

        #expect(expenses.totalRemainingBalance == Money(45989)!)
    }

    @Test func nameRejectsEmptyAndTooLongValues() {
        #expect(RecurringExpense.Name("") == nil)
        #expect(RecurringExpense.Name("   ") == nil)
        #expect(RecurringExpense.Name(nil) == nil)
        #expect(RecurringExpense.Name(String(repeating: "a", count: 51)) == nil)

        #expect(RecurringExpense.Name("Bed")?.value == "Bed")
        #expect(RecurringExpense.Name("  Rent  ")?.value == "Rent")
    }
}
