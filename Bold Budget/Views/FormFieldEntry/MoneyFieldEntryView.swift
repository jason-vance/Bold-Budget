//
//  MoneyFieldEntryView.swift
//  Bold Budget
//
//  Created by Jason Vance on 12/29/24.
//

import SwiftUI
import SwiftUIFlowLayout

struct MoneyFieldEntryView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var title: LocalizedStringKey
    @Binding private var money: Money

    /// Suggestions paired with their formatted string, computed once up front instead
    /// of on every render - formatting each one is a locale-aware NumberFormatter call,
    /// which got expensive once accounts had enough transaction history to produce a
    /// large suggestion list.
    private struct SuggestionEntry {
        let money: Money
        let formatted: String
    }
    @State private var suggestionEntries: [SuggestionEntry]

    /// Raw digits entered so far, read right-to-left as cents (e.g. "1234" == $12.34).
    /// A dedicated numeric keypad drives this instead of the system keyboard/TextField
    /// cursor, since that's the only way to guarantee new taps always land at the end -
    /// no placeholder like "$0.00" to select or delete before entry can begin, and the
    /// amount visibly updates after every tap so it's obvious how digits map to cents.
    @State private var digits: String = ""
    @State private var shakeAmount: Bool = false

    private static let maxDigits = 12 // caps entry at $9,999,999,999.99

    private static let keypadRows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["00", "0", "delete.left"]
    ]

    private var entryAmount: Double {
        (Double(digits) ?? 0) / 100
    }

    private var displayText: String {
        Money(entryAmount)?.formatted() ?? "$0.00"
    }

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    init(
        title: LocalizedStringKey,
        money: Binding<Money>,
        suggestions: [Money] = []
    ) {
        self.title = title
        self._money = money
        let sorted = suggestions.sorted()
        self._suggestionEntries = State(initialValue: sorted.map { SuggestionEntry(money: $0, formatted: $0.formatted()) })
    }

    private static let entryAmountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 10 // Set a reasonable maximum
        formatter.minimumFractionDigits = 0 // Don't force decimals if not needed
        return formatter
    }()

    private var filteredSuggestions: [Money] {
        guard entryAmount != 0 else { return suggestionEntries.map(\.money) }
        guard let entryAmountString = Self.entryAmountFormatter.string(from: NSNumber(value: entryAmount)) else { return [] }

        return suggestionEntries
            .filter { $0.formatted.contains(entryAmountString) }
            .map(\.money)
    }

    private func show(alert: String) {
        showAlert = true
        alertMessage = alert
    }

    private func appendDigit(_ digit: String) {
        // Strip insignificant leading zeros before counting against the cap, so the
        // limit tracks digits that actually affect the displayed amount. Without this,
        // leading zeros (e.g. typing "0" repeatedly) would silently eat into the cap
        // while the display kept showing $0.00, hiding that the limit had been hit.
        let candidate = String((digits + digit).drop { $0 == "0" })
        let normalized = candidate.isEmpty ? "0" : candidate
        guard normalized.count <= Self.maxDigits else {
            hapticBlocked()
            shakeAmount = true
            return
        }
        digits = normalized
        hapticTap()
    }

    private func deleteLastDigit() {
        guard !digits.isEmpty else { return }
        digits = String(digits.dropLast())
        hapticTap()
    }

    private func clearAllDigits() {
        guard !digits.isEmpty else { return }
        digits = ""
        hapticClear()
    }

    private func hapticTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func hapticClear() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func hapticBlocked() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    var body: some View {
        NavigationStack {
            VStack {
                AmountDisplay()
                ScrollView {
                    Suggestions()
                        .animation(.snappy, value: money)
                        .padding(.top)
                }
                Spacer(minLength: 0)
                Keypad()
            }
            .padding()
            .toolbar { Toolbar() }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(title)
            .navigationBarBackButtonHidden()
            .foregroundStyle(Color.text)
            .background(Color.background.ignoresSafeArea())
        }
        .onAppear {
            let cents = Int((money.amount * 100).rounded())
            digits = cents == 0 ? "" : String(cents)
        }
        .alert(alertMessage, isPresented: $showAlert) { }
    }

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            CancelButton()
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            DoneButton()
        }
    }

    @ViewBuilder func CancelButton() -> some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityIdentifier("TextFieldEntryView.CancelButton")
    }

    @ViewBuilder func DoneButton() -> some View {
        Button {
            money = Money(entryAmount) ?? money
            dismiss()
        } label: {
            Image(systemName: "checkmark")
        }
        .accessibilityIdentifier("MoneyFieldEntryView.Toolbar.DoneButton")
    }

    @ViewBuilder private func AmountDisplay() -> some View {
        Text(displayText)
            .font(.largeTitle.bold())
            .contentTransition(.numericText())
            .animation(.snappy, value: digits)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .textFieldSmall()
            .shake($shakeAmount)
            .accessibilityIdentifier("MoneyFieldEntryView.AmountDisplay")
    }

    @ViewBuilder private func Keypad() -> some View {
        VStack(spacing: .paddingCircleButtonSmall) {
            ForEach(Self.keypadRows, id: \.self) { row in
                HStack(spacing: .paddingCircleButtonSmall) {
                    ForEach(row, id: \.self) { key in
                        KeypadButton(key)
                    }
                }
            }
        }
    }

    @ViewBuilder private func KeypadButton(_ key: String) -> some View {
        switch key {
        case "delete.left":
            Image(systemName: key)
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .paddingVerticalButtonMedium)
                .buttonLabelMedium()
                .contentShape(Rectangle())
                .onTapGesture { deleteLastDigit() }
                .onLongPressGesture(minimumDuration: 0.5) { clearAllDigits() }
                .accessibilityIdentifier("MoneyFieldEntryView.Keypad.Delete")
                .accessibilityLabel("Delete")
                .accessibilityHint("Touch and hold to clear the amount")
        default:
            Button {
                appendDigit(key)
            } label: {
                Text(key)
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .paddingVerticalButtonMedium)
            }
            .buttonLabelMedium()
            .accessibilityIdentifier("MoneyFieldEntryView.Keypad.\(key)")
        }
    }

    @ViewBuilder private func Suggestions() -> some View {
        let filtered = filteredSuggestions
        if !filtered.isEmpty {
            VStack {
                HStack {
                    Text("Suggestions:")
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                FlowLayout(
                    mode: .scrollable,
                    items: filtered,
                    itemSpacing: .paddingCircleButtonSmall
                ) { suggestion in
                    Suggestion(suggestion)
                }
            }
        }
    }

    @ViewBuilder private func Suggestion(_ money: Money) -> some View {
        Button {
            self.money = money
            dismiss()
        } label: {
            Text(money.formatted())
                .buttonLabelSmall()
        }
    }
}

#Preview {
    StatefulPreviewContainer(Money.zero) { value in
        MoneyFieldEntryView(
            title: "Total",
            money: value
        )
    }
}
