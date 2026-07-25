//
//  FlowLayout.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/24/26.
//

import SwiftUI

/// A native `Layout` that lays its subviews out left-to-right, wrapping onto a new line
/// whenever the next subview would overflow the proposed width. Unlike the third-party
/// `SwiftUIFlowLayout`, spacing is applied *only* between items (never as leading/trailing
/// padding) and the reported size hugs the content exactly, so there's no phantom padding
/// around a wrapped run of chips.
struct FlowLayout: Layout {

    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat

    init(horizontalSpacing: CGFloat = .paddingSmall, verticalSpacing: CGFloat = .paddingSmall) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    /// Even spacing on both axes.
    init(spacing: CGFloat) {
        self.init(horizontalSpacing: spacing, verticalSpacing: spacing)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = rows(maxWidth: maxWidth, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +)
            + verticalSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = rows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    // MARK: - Row Computation

    /// A single wrapped line: which subviews live on it, and its content dimensions.
    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let spacing = current.indices.isEmpty ? 0 : horizontalSpacing

            if !current.indices.isEmpty, current.width + spacing + size.width > maxWidth {
                rows.append(current)
                current = Row()
            }

            let leadingSpacing = current.indices.isEmpty ? 0 : horizontalSpacing
            current.indices.append(index)
            current.width += leadingSpacing + size.width
            current.height = max(current.height, size.height)
        }

        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
