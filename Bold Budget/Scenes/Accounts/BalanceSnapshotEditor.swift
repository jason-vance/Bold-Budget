//
//  BalanceSnapshotEditor.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/22/26.
//

import SwiftUI

/// Records or edits a single balance entry (a dated snapshot) for an account. Supports backfilling
/// past dates and deleting an existing entry. Keypad-first, on the redesign palette.
struct BalanceSnapshotEditor: View {

    @Environment(\.dismiss) private var dismiss

    @StateObject var budget: Budget
    let accountId: Account.Id
    /// The entry being edited, or `nil` to add a new one.
    let editing: BalanceSnapshot?

    private static let maxDigits = 12

    @State private var digits: String = ""
    @State private var date: Date = .now
    @State private var shakeAmount = false
    @State private var showDatePicker = false
    @State private var populated = false

    private var account: Account? { budget.accounts[accountId] }
    private var amount: Money { Money((Double(digits) ?? 0) / 100) ?? .zero }
    private var isEditing: Bool { editing != nil }

    private var title: String {
        isEditing ? String(localized: "Edit Balance") : String(localized: "Update Balance")
    }

    // MARK: - Keypad

    private func appendDigit(_ digit: String) {
        let candidate = String((digits + digit).drop { $0 == "0" })
        let normalized = candidate.isEmpty ? "0" : candidate
        guard normalized.count <= Self.maxDigits else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            shakeAmount = true
            return
        }
        digits = normalized
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func deleteLastDigit() {
        guard !digits.isEmpty else { return }
        digits = String(digits.dropLast())
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func clearAllDigits() {
        guard !digits.isEmpty else { return }
        digits = ""
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func setAmount(_ money: Money) {
        let cents = Int((money.amount * 100).rounded())
        digits = cents == 0 ? "" : String(cents)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: .padding) {
            Header()
            DateChip()
            Spacer(minLength: 0)
            Text(amount.formatted())
                .font(.system(size: 48, weight: .heavy))
                .foregroundStyle(Color.appText)
                .contentTransition(.numericText())
                .animation(.snappy, value: digits)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(maxWidth: .infinity)
                .shake($shakeAmount)
            Spacer(minLength: 0)
            KeypadGrid(onDigit: appendDigit, onDelete: deleteLastDigit, onClear: clearAllDigits)
            Button(action: save) {
                PrimaryButtonLabel(title: "Save", background: .brandTeal, foreground: .appBackground)
            }
            if isEditing {
                Button(role: .destructive, action: deleteEntry) {
                    Text("Delete Entry")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.negative)
                }
            }
        }
        .padding()
        .foregroundStyle(Color.appText)
        .background(Color.appBackground.ignoresSafeArea())
        .sheet(isPresented: $showDatePicker) { DatePickerSheet() }
        .onAppear(perform: populate)
    }

    private func populate() {
        guard !populated else { return }
        populated = true
        if let editing {
            setAmount(editing.value)
            date = editing.date.toDate() ?? .now
        } else {
            setAmount(account?.balance ?? .zero)
        }
    }

    @ViewBuilder private func Header() -> some View {
        ZStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.appText)
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.appMutedText)
                Spacer(minLength: 0)
            }
        }
        .frame(height: .barHeight)
    }

    @ViewBuilder private func DateChip() -> some View {
        Button {
            showDatePicker = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.brandTeal)
                Text(date.toBasicUiString())
                    .foregroundStyle(Color.appText)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(Color.appMutedText)
            }
            .font(.subheadline.weight(.semibold))
            .padding()
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                    .foregroundStyle(Color.appSurface)
            }
        }
        .accessibilityIdentifier("BalanceSnapshotEditor.DateChip")
    }

    @ViewBuilder private func DatePickerSheet() -> some View {
        NavigationStack {
            DatePicker(
                "Date",
                selection: $date,
                in: Date.distantPast...(Date.distantFuture),
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(Color.brandTeal)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.appBackground.ignoresSafeArea())
            .foregroundStyle(Color.appText)
            .navigationTitle("Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showDatePicker = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.appBackground)
    }

    // MARK: - Actions

    private func save() {
        guard let account, let simpleDate = SimpleDate(date: date) else { return }
        var snapshots = account.snapshots
        if let editing { snapshots.removeAll { $0.date == editing.date } }
        snapshots.removeAll { $0.date == simpleDate }
        snapshots.append(.init(date: simpleDate, value: amount))
        budget.save(account: account.withSnapshots(snapshots))
        dismiss()
    }

    private func deleteEntry() {
        guard let account, let editing else { return }
        budget.save(account: account.withSnapshots(account.snapshots.filter { $0.date != editing.date }))
        dismiss()
    }
}
