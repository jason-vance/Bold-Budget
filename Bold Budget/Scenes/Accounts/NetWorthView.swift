//
//  NetWorthView.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/22/26.
//

import SwiftUI

/// The Net Worth tab, styled to the redesign mockup: a self-contained screen (own header + scroll)
/// on the redesign palette, rather than embedded list sections.
struct NetWorthView: View {

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
        VStack(spacing: 0) {
            Header()
            if allAccounts.isEmpty {
                Spacer(minLength: 0)
                NoAccountsView()
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    VStack(spacing: .padding) {
                        Hero()
                        ChartCard()
                        StatCards()
                        ForEach(Account.Class.allCases, id: \.self) { accountClass in
                            ClassGroup(accountClass)
                        }
                    }
                    .padding()
                }
                .refreshable { budget.refresh() }
                .scrollIndicators(.hidden)
            }
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: - Header

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text("Net Worth")
                .font(.headline)
                .foregroundStyle(Color.appText)
            HStack {
                Spacer(minLength: 0)
                NavigationLink {
                    BudgetSettingsView(budget: _budget)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.body)
                        .foregroundStyle(Color.appMutedText)
                }
                .accessibilityIdentifier("NetWorthView.SettingsButton")
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Hero

    @ViewBuilder private func Hero() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(budget.netWorth.formattedRounded())
                .font(.system(size: 44, weight: .heavy))
                .foregroundStyle(budget.netWorth.amount < 0 ? Color.negative : Color.appText)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if let change = netWorthChange {
                HStack(spacing: 4) {
                    Image(systemName: change.amount >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(change.magnitude.formattedRounded())
                    Text("this period")
                        .foregroundStyle(Color.appMutedText)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(change.amount >= 0 ? Color.positive : Color.negative)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Chart

    @ViewBuilder private func ChartCard() -> some View {
        let history = budget.netWorthHistory
        if history.count >= 2 {
            NetWorthChartView(history: history)
                .appCard()
        }
    }

    // MARK: - Stat cards

    @ViewBuilder private func StatCards() -> some View {
        HStack(spacing: .padding) {
            StatCard(title: "Assets", value: budget.totalAssets.formattedRounded(), tint: .positive)
            StatCard(
                title: "Liabilities",
                value: budget.totalLiabilities.formattedRounded(),
                tint: budget.totalLiabilities.amount > 0 ? .negative : .appText
            )
        }
    }

    @ViewBuilder private func StatCard(title: LocalizedStringKey, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .kerning(0.6)
                .foregroundStyle(Color.appMutedText)
            Text(value)
                .font(.title3.weight(.heavy))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    // MARK: - Account groups

    @ViewBuilder private func ClassGroup(_ accountClass: Account.Class) -> some View {
        let accounts = accounts(of: accountClass)
        if !accounts.isEmpty {
            let total = accountClass == .asset ? accounts.totalAssets : accounts.totalLiabilities
            VStack(spacing: .paddingSmall) {
                HStack {
                    Text(accountClass.pluralName)
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .kerning(0.6)
                        .foregroundStyle(Color.appMutedText)
                    Spacer(minLength: 0)
                    if accountClass == .liability, accounts.totalMonthlyPayments.amount > 0 {
                        Text("\(accounts.totalMonthlyPayments.formattedRounded())/mo")
                            .font(.caption)
                            .foregroundStyle(Color.appMutedText)
                    }
                    Text(total.formattedRounded())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                }
                VStack(spacing: 2) {
                    ForEach(accounts) { account in
                        AccountRow(account)
                    }
                }
            }
        }
    }

    @ViewBuilder private func AccountRow(_ account: Account) -> some View {
        let isLiability = account.accountClass == .liability
        NavigationLink {
            AccountDetailView(budget: budget, accountId: account.id)
        } label: {
            HStack(spacing: .padding) {
                IconCircle(systemName: account.kind.sfSymbol, size: 40, tint: .brandTeal)
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name.value)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.appText)
                    Text(rowSubtitle(for: account))
                        .font(.caption)
                        .foregroundStyle(Color.appMutedText)
                        .lineLimit(1)
                    if let staleNote = stalenessNote(for: account) {
                        HStack(spacing: 3) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text(staleNote)
                        }
                        .font(.caption2)
                        .foregroundStyle(Color.appMutedText)
                    }
                }
                Spacer(minLength: 0)
                Text(isLiability ? account.signedBalance.formattedSignedRounded() : account.balance.formattedRounded())
                    .fontWeight(.semibold)
                    .foregroundStyle(isLiability ? Color.negative : Color.appText)
                    .contentTransition(.numericText())
            }
            .padding(.vertical, .paddingSmall)
        }
        .buttonStyle(.plain)
    }

    private func rowSubtitle(for account: Account) -> String {
        if let payment = account.monthlyPayment, payment.amount > 0 {
            return String(localized: "\(account.kind.name) · \(payment.formattedRounded())/mo")
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
        VStack(spacing: .padding) {
            IconCircle(systemName: "chart.pie", size: 64, tint: .brandTeal)
            Text("No Accounts")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appText)
            Text("Add your bank, investment, retirement, and loan accounts to track your net worth.")
                .font(.subheadline)
                .foregroundStyle(Color.appMutedText)
                .multilineTextAlignment(.center)
            NavigationLink {
                EditAccountView(budget: budget)
            } label: {
                PrimaryButtonLabel(title: "Add Account", systemName: "plus", background: .brandTeal, foreground: .appBackground)
            }
            .frame(maxWidth: 280)
        }
        .padding()
    }
}

#Preview("Populated") {
    NavigationStack {
        NetWorthView(budget: .previewSample(accounts: Account.samples))
    }
}

#Preview("Empty") {
    NavigationStack {
        NetWorthView(budget: .previewSample())
    }
}
