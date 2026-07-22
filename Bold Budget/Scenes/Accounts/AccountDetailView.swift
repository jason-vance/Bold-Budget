//
//  AccountDetailView.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/22/26.
//

import SwiftUI

/// Read-focused account screen from the redesign mockup: header, balance + change, value chart,
/// an Update Balance action, and balance history. Editing (name/type/delete) lives in
/// `EditAccountView`, reached via the Edit button.
struct AccountDetailView: View {

    @Environment(\.dismiss) private var dismiss

    @StateObject var budget: Budget
    let accountId: Account.Id

    @State private var showEditor = false
    @State private var editorSnapshot: BalanceSnapshot?

    private var account: Account? { budget.accounts[accountId] }

    var body: some View {
        Group {
            if let account {
                VStack(spacing: 0) {
                    Header(account)
                    ScrollView {
                        VStack(alignment: .leading, spacing: .padding) {
                            Profile(account)
                            BalanceBlock(account)
                            ChartCard(account)
                            UpdateBalanceButton(account)
                            HistorySection(account)
                        }
                        .padding()
                    }
                    .scrollIndicators(.hidden)
                }
            } else {
                Color.clear
            }
        }
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .fullScreenCover(isPresented: $showEditor) {
            BalanceSnapshotEditor(budget: budget, accountId: accountId, editing: editorSnapshot)
        }
        .onChange(of: account) { _, new in
            if new == nil { dismiss() }
        }
    }

    // MARK: - Header

    @ViewBuilder private func Header(_ account: Account) -> some View {
        ZStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(Color.appMutedText)
                }
                Spacer(minLength: 0)
                NavigationLink {
                    EditAccountView(budget: budget).editing(account)
                } label: {
                    Text("Edit")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brandTeal)
                }
                .accessibilityIdentifier("AccountDetailView.EditButton")
            }
        }
        .frame(height: .barHeight)
        .padding(.horizontal)
    }

    // MARK: - Profile / balance

    @ViewBuilder private func Profile(_ account: Account) -> some View {
        HStack(spacing: .padding) {
            IconCircle(systemName: account.kind.sfSymbol, size: 52, tint: .brandTeal)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name.value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appText)
                Text("\(account.kind.name) · \(account.trackingMode.name)")
                    .font(.subheadline)
                    .foregroundStyle(Color.appMutedText)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder private func BalanceBlock(_ account: Account) -> some View {
        let isLiability = account.accountClass == .liability
        VStack(alignment: .leading, spacing: 4) {
            Text(isLiability ? account.signedBalance.formattedSignedRounded() : account.balance.formattedRounded())
                .font(.system(size: 40, weight: .heavy))
                .foregroundStyle(isLiability ? Color.negative : Color.appText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
            if let change = account.latestChange {
                HStack(spacing: 4) {
                    Image(systemName: change.amount >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(change.magnitude.formattedRounded())
                    if let since = sinceLabel(account) {
                        Text("since \(since)")
                            .foregroundStyle(Color.appMutedText)
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(changeColor(for: account, change: change))
            }
            if isLiability, let payment = account.monthlyPayment, payment.amount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(Color.brandTeal)
                    Text("\(payment.formattedRounded())/mo payment")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.appMutedText)
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sinceLabel(_ account: Account) -> String? {
        guard account.snapshots.count >= 2 else { return nil }
        return account.snapshots[1].date.toDate()?.toBasicUiString()
    }

    /// Green when the change improves net worth (assets up / liabilities down), else red.
    private func changeColor(for account: Account, change: SignedMoney) -> Color {
        let improvesNetWorth = account.accountClass == .asset ? change.amount >= 0 : change.amount <= 0
        return improvesNetWorth ? .positive : .negative
    }

    // MARK: - Chart

    private func chartHistory(_ account: Account) -> [(date: SimpleDate, value: SignedMoney)] {
        account.snapshots
            .sorted { $0.date < $1.date }
            .map { (date: $0.date, value: SignedMoney($0.value.amount)) }
    }

    @ViewBuilder private func ChartCard(_ account: Account) -> some View {
        let history = chartHistory(account)
        if history.count >= 2 {
            NetWorthChartView(history: history)
                .appCard()
        }
    }

    // MARK: - Update balance

    @ViewBuilder private func UpdateBalanceButton(_ account: Account) -> some View {
        Button {
            editorSnapshot = nil
            showEditor = true
        } label: {
            HStack(spacing: .paddingSmall) {
                Image(systemName: "plus")
                Text("Update Balance")
            }
            .font(.headline)
            .foregroundStyle(Color.brandTeal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .paddingVerticalButtonMedium)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .foregroundStyle(Color.appSurface)
            }
        }
        .accessibilityIdentifier("AccountDetailView.UpdateBalanceButton")
    }

    // MARK: - History

    @ViewBuilder private func HistorySection(_ account: Account) -> some View {
        let snapshots = account.snapshots // already sorted newest-first
        if !snapshots.isEmpty {
            VStack(alignment: .leading, spacing: .paddingSmall) {
                Text("Balance History")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .kerning(0.6)
                    .foregroundStyle(Color.appMutedText)
                VStack(spacing: 0) {
                    ForEach(Array(snapshots.enumerated()), id: \.element.id) { index, snapshot in
                        HistoryRow(snapshot, previous: snapshots[safe: index + 1], account: account)
                        if index < snapshots.count - 1 {
                            Divider().overlay(Color.appMutedText.opacity(0.2))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private func HistoryRow(_ snapshot: BalanceSnapshot, previous: BalanceSnapshot?, account: Account) -> some View {
        let delta = previous.map { SignedMoney(snapshot.value.amount - $0.value.amount) }
        Button {
            editorSnapshot = snapshot
            showEditor = true
        } label: {
            HStack {
                Text(snapshot.date.toDate()?.toBasicUiString() ?? "—")
                    .foregroundStyle(Color.appText)
                Spacer(minLength: 0)
                if let delta, delta.amount != 0 {
                    Text(delta.formattedSignedRounded())
                        .font(.caption)
                        .foregroundStyle(changeColor(for: account, change: delta))
                }
                Text(snapshot.value.formattedRounded())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appText)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color.appMutedText)
            }
            .padding(.vertical, .paddingSmall)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    NavigationStack {
        AccountDetailView(
            budget: .previewSample(accounts: Account.samples),
            accountId: Account.sampleRobinhood.id
        )
    }
}
