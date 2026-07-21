//
//  NetWorthListContent.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/21/26.
//

import SwiftUI

/// List `Section` content for net worth and accounts, meant to be embedded inside a parent `List`
/// (mirrors `RecurringExpensesListContent`) rather than owning its own screen chrome.
struct NetWorthListContent: View {

    @StateObject var budget: Budget

    private var allAccounts: [Account] {
        Array(budget.accounts.values)
    }

    private func accounts(of accountClass: Account.Class) -> [Account] {
        allAccounts
            .filter { $0.accountClass == accountClass }
            .sorted { $0.balance > $1.balance }
    }

    var body: some View {
        if allAccounts.isEmpty {
            NoAccountsView()
        } else {
            NetWorthSection()
            NetWorthChartSection()
            ForEach(Account.Class.allCases, id: \.self) { accountClass in
                ClassSection(accountClass)
            }
        }
    }

    @ViewBuilder private func NetWorthChartSection() -> some View {
        let history = budget.netWorthHistory
        if history.count >= 2 {
            Section {
                NetWorthChartView(history: history)
                    .listRowBackground(Color.background)
                    .listRowSeparator(.hidden)
            }
            .listSectionSeparator(.hidden)
            .listSectionSpacing(0)
        }
    }

    @ViewBuilder private func NetWorthSection() -> some View {
        Section {
            VStack(alignment: .leading, spacing: 2) {
                Text("Net Worth")
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color.text.opacity(0.5))
                Text(budget.netWorth.formatted())
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.text)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowBackground(Color.background)
            .listRowSeparator(.hidden)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Assets")
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(Color.text.opacity(0.5))
                    Text(budget.totalAssets.formatted())
                        .foregroundStyle(Color.text)
                        .contentTransition(.numericText())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Liabilities")
                        .font(.caption2.bold())
                        .textCase(.uppercase)
                        .foregroundStyle(Color.text.opacity(0.5))
                    Text(budget.totalLiabilities.formatted())
                        .foregroundStyle(Color.text)
                        .contentTransition(.numericText())
                }
            }
            .listRowBackground(Color.background)
            .listRowSeparator(.hidden)
        }
        .listSectionSeparator(.hidden)
        .listSectionSpacing(0)
    }

    @ViewBuilder private func ClassSection(_ accountClass: Account.Class) -> some View {
        let accounts = accounts(of: accountClass)
        if !accounts.isEmpty {
            let total = accountClass == .asset
                ? accounts.totalAssets
                : accounts.totalLiabilities
            Section {
                ForEach(accounts) { account in
                    AccountRow(account)
                }
            } header: {
                HStack {
                    Text(accountClass.pluralName)
                    Spacer()
                    if accountClass == .liability, accounts.totalMonthlyPayments.amount > 0 {
                        Text("\(accounts.totalMonthlyPayments.formatted())/mo · ")
                            .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    }
                    Text(total.formatted())
                }
                .foregroundStyle(Color.text)
            }
            .listSectionSeparator(.hidden)
            .listSectionSpacing(0)
        }
    }

    @ViewBuilder private func AccountRow(_ account: Account) -> some View {
        NavigationLink {
            EditAccountView(budget: budget)
                .editing(account)
        } label: {
            HStack(spacing: .padding) {
                Image(systemName: account.kind.sfSymbol)
                    .frame(width: 24)
                    .foregroundStyle(Color.text.opacity(.opacityMutedText))
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name.value)
                    Text(rowSubtitle(for: account))
                        .font(.caption)
                        .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    if let staleNote = stalenessNote(for: account) {
                        HStack(spacing: 3) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text(staleNote)
                        }
                        .font(.caption2)
                        .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    }
                }
                Spacer(minLength: 0)
                Text(account.balance.formatted())
                    .contentTransition(.numericText())
            }
        }
        .listRow()
    }

    private func rowSubtitle(for account: Account) -> String {
        if let payment = account.monthlyPayment, payment.amount > 0 {
            return String(localized: "\(account.kind.name) · \(payment.formatted())/mo")
        }
        let mode = account.trackingMode == .snapshot
            ? String(localized: "manual")
            : String(localized: "transactions")
        return "\(account.kind.name) · \(mode)"
    }

    /// A staleness cue for accounts whose most recent balance point predates the current month.
    private func stalenessNote(for account: Account) -> String? {
        guard let snapshot = account.latestSnapshot else { return nil }
        let now = SimpleDate.now
        let isStale = snapshot.date.year < now.year
            || (snapshot.date.year == now.year && snapshot.date.month < now.month)
        guard isStale, let dateString = snapshot.date.toDate()?.toBasicUiString() else { return nil }
        return String(localized: "as of \(dateString)")
    }

    @ViewBuilder private func NoAccountsView() -> some View {
        ContentUnavailableView(
            "No Accounts",
            systemImage: "chart.pie",
            description: Text("Add your bank, investment, retirement, and loan accounts to track your net worth")
        )
        .listRowBackground(Color.background)
        .listRowSeparator(.hidden)
    }
}

#Preview("Populated") {
    List {
        NetWorthListContent(budget: .previewSample(accounts: Account.samples))
    }
    .listStyle(.insetGrouped)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .foregroundStyle(Color.text)
    .background(Color.background)
}

#Preview("Empty") {
    List {
        NetWorthListContent(budget: .previewSample())
    }
    .listStyle(.insetGrouped)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .foregroundStyle(Color.text)
    .background(Color.background)
}
