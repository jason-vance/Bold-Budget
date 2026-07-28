//
//  TransactionCsvExporter.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/27/26.
//
//  Turns a budget's transactions into RFC 4180 CSV.
//
//  Amounts are written as plain decimal numbers with no currency symbol or thousands separator, and
//  dates as ISO `yyyy-MM-dd`, so the file opens the same way in Excel, Numbers, and Sheets in every
//  locale. Formatting for humans is the app's job; this file is for spreadsheets.
//

import Foundation

enum TransactionCsvExporter {

    static let headerRow = [
        "Date",
        "Kind",
        "Title",
        "Amount",
        "Category",
        "Account",
        "From Account",
        "To Account",
        "Location",
        "Tags",
    ]

    /// A filename-safe stem, e.g. `Family-Budget-transactions-2026-07-27`.
    static func fileName(for budgetName: String, on date: Date = .now) -> String {
        let safeName = budgetName
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let stem = safeName.isEmpty ? "budget" : safeName
        return "\(stem)-transactions-\(isoDateFormatter.string(from: date)).csv"
    }

    static func csv(
        transactions: [Transaction],
        categories: [Transaction.Category.Id: Transaction.Category],
        accounts: [Account.Id: Account]
    ) -> String {
        // Newest first, matching how the app lists them.
        let sorted = transactions.sorted { lhs, rhs in
            lhs.date == rhs.date
                ? lhs.id.uuidString < rhs.id.uuidString
                : lhs.date > rhs.date
        }

        let rows = sorted.map { transaction in
            row(for: transaction, categories: categories, accounts: accounts)
        }

        return ([headerRow] + rows)
            .map { $0.map(escape).joined(separator: ",") }
            .joined(separator: "\r\n")
            .appending("\r\n")
    }

    private static func row(
        for transaction: Transaction,
        categories: [Transaction.Category.Id: Transaction.Category],
        accounts: [Account.Id: Account]
    ) -> [String] {
        func accountName(_ id: Account.Id?) -> String {
            guard let id else { return "" }
            return accounts[id]?.name.value ?? ""
        }

        // A transfer carries no spending category, so the column is deliberately blank rather than
        // showing the placeholder category the model keeps for schema reasons.
        let categoryName = transaction.isTransfer
            ? ""
            : (categories[transaction.categoryId]?.name.value ?? "")

        return [
            isoString(from: transaction.date),
            transaction.kind.rawValue,
            transaction.title?.value ?? "",
            amountString(transaction.amount),
            categoryName,
            accountName(transaction.accountId),
            accountName(transaction.fromAccountId),
            accountName(transaction.toAccountId),
            transaction.location?.value ?? "",
            transaction.tags.map(\.value).sorted().joined(separator: "; "),
        ]
    }

    // MARK: - Formatting

    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func isoString(from date: SimpleDate) -> String {
        String(format: "%04d-%02d-%02d", date.year, date.month, date.day)
    }

    private static func amountString(_ money: Money) -> String {
        String(format: "%.2f", money.amount)
    }

    /// RFC 4180: quote a field when it contains a comma, quote, or newline, and double any quotes.
    private static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else {
            return field
        }
        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
