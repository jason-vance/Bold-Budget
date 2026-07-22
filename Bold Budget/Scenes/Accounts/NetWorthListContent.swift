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

    private var netWorthChange: SignedMoney? {
        let history = budget.netWorthHistory
        guard history.count >= 2 else { return nil }
        return history[history.count - 1].value - history[history.count - 2].value
    }

    var body: some View {
        if allAccounts.isEmpty {
            NoAccountsView()
        } else {
            HeroSection()
            ChartCardSection()
            StatCardsSection()
            ForEach(Account.Class.allCases, id: \.self) { accountClass in
                ClassSection(accountClass)
            }
        }
    }

    @ViewBuilder private func HeroSection() -> some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Net Worth")
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .kerning(0.6)
                    .foregroundStyle(Color.text.opacity(0.5))
                Text(budget.netWorth.formatted())
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(budget.netWorth.amount < 0 ? Color.negative : Color.text)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let change = netWorthChange {
                    HStack(spacing: 4) {
                        Image(systemName: change.amount >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(change.magnitude.formatted())
                        Text("this period")
                            .foregroundStyle(Color.text.opacity(.opacityMutedText))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(change.amount >= 0 ? Color.positive : Color.negative)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowBackground(Color.background)
            .listRowSeparator(.hidden)
        }
        .listSectionSeparator(.hidden)
        .listSectionSpacing(0)
    }

    @ViewBuilder private func ChartCardSection() -> some View {
        let history = budget.netWorthHistory
        if history.count >= 2 {
            Section {
                NetWorthChartView(history: history)
                    .card()
                    .listRowBackground(Color.background)
                    .listRowSeparator(.hidden)
            }
            .listSectionSeparator(.hidden)
            .listSectionSpacing(0)
        }
    }

    @ViewBuilder private func StatCardsSection() -> some View {
        Section {
            HStack(spacing: .padding) {
                StatCard(title: "Assets", value: budget.totalAssets.formatted(), tint: .positive)
                StatCard(
                    title: "Liabilities",
                    value: budget.totalLiabilities.formatted(),
                    tint: budget.totalLiabilities.amount > 0 ? .negative : .text
                )
            }
            .listRowBackground(Color.background)
            .listRowSeparator(.hidden)
        }
        .listSectionSeparator(.hidden)
        .listSectionSpacing(0)
    }

    @ViewBuilder private func StatCard(title: LocalizedStringKey, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .kerning(0.6)
                .foregroundStyle(Color.text.opacity(0.5))
            Text(value)
                .font(.title3.weight(.heavy))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
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
        let isLiability = account.accountClass == .liability
        NavigationLink {
            EditAccountView(budget: budget)
                .editing(account)
        } label: {
            HStack(spacing: .padding) {
                IconCircle(systemName: account.kind.sfSymbol, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name.value)
                        .fontWeight(.semibold)
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
                Text(isLiability ? account.signedBalance.formattedSigned() : account.balance.formatted())
                    .fontWeight(.semibold)
                    .foregroundStyle(isLiability ? Color.negative : Color.text)
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
