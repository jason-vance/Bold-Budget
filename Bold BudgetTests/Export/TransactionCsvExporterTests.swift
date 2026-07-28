//
//  TransactionCsvExporterTests.swift
//  Bold BudgetTests
//
//  Created by Jason Vance on 7/27/26.
//

import Testing
import Foundation

struct TransactionCsvExporterTests {

    private let groceriesId = Transaction.Category.Id()
    private let checkingId = Account.Id()
    private let savingsId = Account.Id()

    private var categories: [Transaction.Category.Id: Transaction.Category] {
        [
            groceriesId: .init(
                id: groceriesId,
                name: .init("Groceries")!,
                sfSymbol: .init("cart")!,
                goal: nil
            )
        ]
    }

    private var accounts: [Account.Id: Account] {
        [
            checkingId: .init(
                id: checkingId,
                name: .init("Checking")!,
                kind: .checking,
                trackingMode: .ledger,
                balance: Money(1000)!
            ),
            savingsId: .init(
                id: savingsId,
                name: .init("Savings")!,
                kind: .savings,
                trackingMode: .ledger,
                balance: Money(5000)!
            ),
        ]
    }

    private func expense(
        title: String? = nil,
        amount: Double,
        date: SimpleDate,
        location: String? = nil,
        tags: Set<Transaction.Tag> = []
    ) -> Transaction {
        .init(
            id: Transaction.Id(),
            title: title.flatMap { Transaction.Title($0) },
            amount: Money(amount)!,
            date: date,
            categoryId: groceriesId,
            location: location.flatMap { Transaction.Location($0) },
            tags: tags,
            kind: .expense,
            accountId: checkingId
        )
    }

    private func lines(_ csv: String) -> [String] {
        csv.components(separatedBy: "\r\n").filter { !$0.isEmpty }
    }

    @Test func headerIsAlwaysWrittenEvenWithNoTransactions() {
        let csv = TransactionCsvExporter.csv(transactions: [], categories: [:], accounts: [:])

        #expect(lines(csv) == [TransactionCsvExporter.headerRow.joined(separator: ",")])
    }

    @Test func anExpenseIsWrittenAsOneRow() {
        let csv = TransactionCsvExporter.csv(
            transactions: [
                expense(title: "Costco", amount: 84.5, date: .init(year: 2026, month: 7, day: 4)!)
            ],
            categories: categories,
            accounts: accounts
        )

        let rows = lines(csv)
        #expect(rows.count == 2)
        #expect(rows[1] == "2026-07-04,expense,Costco,84.50,Groceries,Checking,,,,")
    }

    /// Plain decimals and ISO dates, so the file reads the same in every locale and spreadsheet.
    @Test func amountsAreWrittenAsPlainDecimalsWithoutCurrencyFormatting() {
        let csv = TransactionCsvExporter.csv(
            transactions: [expense(amount: 1234.5, date: .init(year: 2026, month: 1, day: 9)!)],
            categories: categories,
            accounts: accounts
        )

        let row = lines(csv)[1]
        #expect(row.hasPrefix("2026-01-09,expense,,1234.50,"))
        #expect(!row.contains("$"))
        #expect(!row.contains(","+"234"), "No thousands separator")
    }

    @Test func transfersCarryBothAccountsAndNoCategory() {
        let transfer = Transaction(
            id: Transaction.Id(),
            title: Transaction.Title("To savings"),
            amount: Money(200)!,
            date: .init(year: 2026, month: 3, day: 1)!,
            categoryId: groceriesId,
            kind: .transfer,
            fromAccountId: checkingId,
            toAccountId: savingsId
        )

        let csv = TransactionCsvExporter.csv(
            transactions: [transfer],
            categories: categories,
            accounts: accounts
        )

        #expect(lines(csv)[1] == "2026-03-01,transfer,To savings,200.00,,,Checking,Savings,,")
    }

    @Test func rowsAreOrderedNewestFirst() {
        let old = expense(title: "Old", amount: 1, date: .init(year: 2025, month: 1, day: 1)!)
        let new = expense(title: "New", amount: 2, date: .init(year: 2026, month: 1, day: 1)!)

        let csv = TransactionCsvExporter.csv(
            transactions: [old, new],
            categories: categories,
            accounts: accounts
        )

        let rows = lines(csv)
        #expect(rows[1].contains("New"))
        #expect(rows[2].contains("Old"))
    }

    @Test func fieldsContainingCommasAndQuotesAreEscaped() {
        let csv = TransactionCsvExporter.csv(
            transactions: [
                expense(
                    title: "Dinner, drinks",
                    amount: 60,
                    date: .init(year: 2026, month: 2, day: 2)!,
                    location: "The \"Old\" Pub"
                )
            ],
            categories: categories,
            accounts: accounts
        )

        let row = lines(csv)[1]
        #expect(row.contains("\"Dinner, drinks\""))
        #expect(row.contains("\"The \"\"Old\"\" Pub\""))
    }

    @Test func tagsAreJoinedIntoASingleField() {
        let csv = TransactionCsvExporter.csv(
            transactions: [
                expense(
                    amount: 10,
                    date: .init(year: 2026, month: 2, day: 2)!,
                    tags: [.init("beach")!, .init("anniversary")!]
                )
            ],
            categories: categories,
            accounts: accounts
        )

        // Sorted, so the column is stable across runs despite `tags` being a Set. Semicolon-joined
        // rather than comma-joined, which keeps the field unquoted and the row easy to read.
        #expect(lines(csv)[1].hasSuffix(",anniversary; beach"))
    }

    @Test func aDeletedCategoryLeavesTheColumnBlankRatherThanBreakingTheRow() {
        let csv = TransactionCsvExporter.csv(
            transactions: [expense(amount: 5, date: .init(year: 2026, month: 5, day: 5)!)],
            categories: [:],
            accounts: accounts
        )

        #expect(lines(csv)[1] == "2026-05-05,expense,,5.00,,Checking,,,,")
    }

    @Test func fileNameIsSafeAndDated() {
        let date = SimpleDate(year: 2026, month: 7, day: 27)!.toDate()!

        #expect(TransactionCsvExporter.fileName(for: "Family Budget", on: date) == "Family-Budget-transactions-2026-07-27.csv")
        #expect(TransactionCsvExporter.fileName(for: "Ben & Jen's / 2026", on: date) == "Ben-Jen-s-2026-transactions-2026-07-27.csv")
        #expect(TransactionCsvExporter.fileName(for: "🎉", on: date) == "budget-transactions-2026-07-27.csv")
    }
}
