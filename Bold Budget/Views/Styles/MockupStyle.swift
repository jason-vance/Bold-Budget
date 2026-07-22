//
//  MockupStyle.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/21/26.
//
//  Shared building blocks for the net-worth redesign look: rounded surface cards, icon
//  circles, chips, a prominent primary button, and a segmented control. Everything is built
//  from the app's adaptive tokens (`Color.text` / `Color.background` / `Color.accent`) so it
//  works in both the light (teal) and dark (near-black) themes.
//

import SwiftUI

extension ShapeStyle where Self == Color {
    /// Adaptive surface fill for cards, chips, and icon circles (redesign palette).
    static var surface: Color { Color.appSurface }
}

extension View {
    /// A tappable pill used for inline suggestions in the redesign palette.
    func redesignPill() -> some View {
        self
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.appText)
            .padding(.horizontal, .paddingHorizontalButtonSmall)
            .padding(.vertical, .paddingVerticalButtonXSmall)
            .background { Capsule().foregroundStyle(Color.appSurface) }
    }

    /// Wraps content in a rounded, padded surface card.
    func card(_ padding: CGFloat = .padding, cornerRadius: CGFloat = .cornerRadiusMedium) -> some View {
        self
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .foregroundStyle(Color.surface)
            }
    }

    /// Redesign-palette surface card (alias of `card`, made explicit at call sites).
    func appCard(_ padding: CGFloat = .padding, cornerRadius: CGFloat = .cornerRadiusMedium) -> some View {
        card(padding, cornerRadius: cornerRadius)
    }
}

/// A circular icon badge, as used on account and transaction rows.
struct IconCircle: View {
    let systemName: String
    var size: CGFloat = 44
    var tint: Color = .text

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background {
                Circle().foregroundStyle(tint.opacity(.opacityButtonBackground))
            }
    }
}

/// A small pill label, as used for account tags.
struct Chip: View {
    let text: String
    var systemName: String? = nil
    var tint: Color = .text

    var body: some View {
        HStack(spacing: 3) {
            if let systemName {
                Image(systemName: systemName).font(.system(size: 9, weight: .semibold))
            }
            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, .paddingHorizontalButtonXSmall)
        .padding(.vertical, 3)
        .background {
            Capsule().foregroundStyle(tint.opacity(.opacityButtonBackground))
        }
    }
}

/// A full-width, prominent primary action button.
struct PrimaryButtonLabel: View {
    let title: String
    var systemName: String? = nil
    var enabled: Bool = true
    var background: Color = .text
    var foreground: Color = .background

    var body: some View {
        HStack(spacing: .paddingSmall) {
            if let systemName { Image(systemName: systemName) }
            Text(title)
        }
        .font(.headline)
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, .paddingVerticalButtonMedium)
        .background {
            RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                .foregroundStyle(background)
        }
        .opacity(enabled ? 1 : .opacityButtonBackground)
    }
}

/// A pill segmented control bound to a `Hashable` selection. The selected segment is filled with
/// its tint and shows white text; unselected segments are muted, over a dark-gray container.
struct PillSegmentedControl<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [Value]
    let title: (Value) -> String
    var tint: (Value) -> Color = { _ in .brandTeal }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option
                Button {
                    withAnimation(.snappy) { selection = option }
                } label: {
                    Text(title(option))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? .white : Color.appMutedText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, .paddingVerticalButtonXSmall)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                                    .foregroundStyle(tint(option))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.paddingCircleButtonSmall)
        .background {
            RoundedRectangle(cornerRadius: .cornerRadiusMedium, style: .continuous)
                .foregroundStyle(Color.appSurface)
        }
    }
}
