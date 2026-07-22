//
//  KeypadGrid.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/21/26.
//
//  A stateless numeric keypad (1-9, 00, 0, delete). Digit/clear state lives in the host, which
//  drives the amount display. Mirrors the keypad inside `MoneyFieldEntryView` so both the modal
//  entry and the keypad-first Add screen behave identically.
//

import SwiftUI

struct KeypadGrid: View {

    let onDigit: (String) -> Void
    let onDelete: () -> Void
    let onClear: () -> Void

    private static let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["00", "0", "delete.left"]
    ]

    var body: some View {
        VStack(spacing: .paddingCircleButtonSmall) {
            ForEach(Self.rows, id: \.self) { row in
                HStack(spacing: .paddingCircleButtonSmall) {
                    ForEach(row, id: \.self) { key in
                        Key(key)
                    }
                }
            }
        }
    }

    @ViewBuilder private func Key(_ key: String) -> some View {
        if key == "delete.left" {
            Image(systemName: key)
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .paddingVerticalButtonMedium)
                .buttonLabelMedium()
                .contentShape(Rectangle())
                .onTapGesture { onDelete() }
                .onLongPressGesture(minimumDuration: 0.5) { onClear() }
                .accessibilityIdentifier("KeypadGrid.Delete")
                .accessibilityLabel("Delete")
                .accessibilityHint("Touch and hold to clear the amount")
        } else {
            Button {
                onDigit(key)
            } label: {
                Text(key)
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .paddingVerticalButtonMedium)
            }
            .buttonLabelMedium()
            .accessibilityIdentifier("KeypadGrid.\(key)")
        }
    }
}
