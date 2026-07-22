//
//  PieChart.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import SwiftUI

struct PieChart: View {
    
    public struct Slice: Equatable {
        let value: Double
        let category: Transaction.Category
        /// Income vs. expense for this slice — supplied by the caller (from the transactions'
        /// kinds), since categories are no longer income/expense-typed.
        let kind: Transaction.Kind

        static let samples: [Slice] = [
            .init(value: 600, category: Transaction.Category.samples[0], kind: .expense),
            .init(value: 2500, category: Transaction.Category.samples[1], kind: .expense),
            .init(value: 1500, category: Transaction.Category.samples[4], kind: .expense),
            .init(value: 250, category: Transaction.Category.samples[3], kind: .income),
            .init(value: 125, category: Transaction.Category.samples[2], kind: .expense),
            .init(value: 7, category: .init(id: .init(), name: .init("Candy Bar")!, sfSymbol: .init("ellipsis.rectangle.fill")!, goal: nil), kind: .expense),
            .init(value: 5, category: .init(id: .init(), name: .init("Candy Bar")!, sfSymbol: .init("ellipsis.rectangle.fill")!, goal: nil), kind: .income),
            .init(value: 1700, category: .init(id: .init(), name: .init("Stocks")!, sfSymbol: .init("chart.bar.xaxis.ascending")!, goal: nil), kind: .income),
            .init(value: 2700, category: .init(id: .init(), name: .init("Paycheck")!, sfSymbol: .init("banknote.fill")!, goal: nil), kind: .income)
        ]
    }
    
    private struct _Slice: Identifiable {
        var id: Int { index }
        let index: Int
        let kind: Transaction.Kind
        let name: String
        let sfSymbol: Transaction.Category.SfSymbol
        let value: Double
        let touchFrom: CGFloat
        let touchTo: CGFloat
        let from: CGFloat
        let to: CGFloat
    }

    private let paddingPoints: CGFloat = 8
    private let lineWidth: CGFloat = 20
    private let tapMaxDuration: TimeInterval = 0.3
    private var minSliceViewSize: CGFloat  { 2 * lineWidth }
    
    private let slices: [Slice]
    
    @State private var slicesState: [Slice] = []
    @State private var selectedSlice: _Slice? = nil
    @State private var touchStart: Date? = nil
    
    private var formatValue: (Double) -> String
    
    init(slices: [Slice]) {
        self.slices = slices
        formatValue = { value in value.formatted() }
    }
    
    func valueFormatter(_ formatValue: @escaping (Double) -> String) -> PieChart {
        var view = self
        view.formatValue = formatValue
        return view
    }
    
    private func mapSlicesTo_Slice(pieCircumference: CGFloat) -> [_Slice] {
        let padding = paddingPoints / pieCircumference
        let lineCap = (lineWidth / 2) / pieCircumference
        
        let total = self.grossTotal
         
        var index = -1
        var previousCumulativeValue: CGFloat = 0
        return slicesState
            .sorted {
                if $0.kind != $1.kind {
                    $0.kind == .expense
                } else if $0.kind == .expense {
                    $0.value > $1.value
                } else {
                    $0.value < $1.value
                }
            }
            .map { slice in
                let touchFrom = (previousCumulativeValue / total)
                let touchTo = touchFrom + (slice.value / total)
                let rawFrom = touchFrom + lineCap + (padding / 2)
                let rawTo = touchTo - lineCap - (padding / 2)
                // Guard against a sliver too small to inset (an un-mergeable lone slice): a `from`
                // greater than `to` makes `trim` wrap the long way around into a huge wrong arc.
                let midpoint = (touchFrom + touchTo) / 2
                let from = rawFrom <= rawTo ? rawFrom : midpoint
                let to = rawFrom <= rawTo ? rawTo : midpoint

                previousCumulativeValue += slice.value
                index += 1
                
                return .init(
                    index: index,
                    kind: slice.kind,
                    name: slice.category.name.value,
                    sfSymbol: slice.category.sfSymbol,
                    value: slice.value,
                    touchFrom: touchFrom,
                    touchTo: touchTo,
                    from: from,
                    to: to
                )
            }
    }
    
    private func mergeSmallSlicesIfNecessary(_ slices: [_Slice], pieCircumference: CGFloat) -> [_Slice] {
        // A slice needs enough arc for the outer ring *and* the inner (background) ring to render
        // with their round caps; `minSliceViewSize` (2 * lineWidth) is that floor.
        let wontBeVisible: (_Slice) -> Bool = { slice in
            let length = (slice.touchTo - slice.touchFrom) * pieCircumference
            return length < (minSliceViewSize + paddingPoints)
        }
        
        let merge: (_Slice, _Slice) -> _Slice = { lhs, rhs in
            assert(lhs.kind == rhs.kind, "Cannot merge slices of different kinds")
            
            return .init(
                index: min(lhs.index, rhs.index),
                kind: lhs.kind,
                name: "\(rhs.name), \(lhs.name)",
                sfSymbol: .init("ellipsis")!,
                value: lhs.value + rhs.value,
                touchFrom: min(lhs.touchFrom, rhs.touchFrom),
                touchTo: max(lhs.touchTo, rhs.touchTo),
                from: min(lhs.from, rhs.from),
                to: max(lhs.to, rhs.to)
            )
        }
        
        var rv: [_Slice] = slices
        if let kind = slices.first?.kind {
            if kind == .income {
                while let smallestSlice = rv.first, wontBeVisible(smallestSlice) {
                    guard rv.count >= 2 else { break }
                    
                    let secondSmallestSlice = rv[1]
                    let mergedSlice = merge(smallestSlice, secondSmallestSlice)
                    
                    rv = Array(rv.dropFirst(2))
                    rv.insert(mergedSlice, at: 0)
                }
            } else {
                while let smallestSlice = rv.last, wontBeVisible(smallestSlice) {
                    guard rv.count >= 2 else { break }
                    
                    let secondSmallestSlice = rv[rv.count - 2]
                    let mergedSlice = merge(smallestSlice, secondSmallestSlice)
                    
                    rv = Array(rv.dropLast(2))
                    rv.append(mergedSlice)
                }
            }
        }
        
        return rv
    }
    
    private func makeSlices(pieCircumference: CGFloat) -> [_Slice] {
        let slices = mapSlicesTo_Slice(pieCircumference: pieCircumference)

        let incomes = mergeSmallSlicesIfNecessary(
            slices.filter { $0.kind == .income },
            pieCircumference: pieCircumference
        )
        let expenses = mergeSmallSlicesIfNecessary(
            slices.filter { $0.kind == .expense },
            pieCircumference: pieCircumference
        )

        // Give every surviving sector at least a visible minimum span (stealing proportionally from
        // the larger ones), then re-inset each from its final touch range so the padding gap is
        // symmetric on both ends — `min`/`max` of the pre-merge insets can leave one end flush.
        let balanced = enforceMinimumSpans(incomes + expenses, pieCircumference: pieCircumference)
        return balanced.map { insetArc($0, pieCircumference: pieCircumference) }
    }

    /// Ensures each sector's touch span is at least large enough to render at `minSliceViewSize`
    /// with padding on both sides. Sub-minimum sectors (a lone merged sliver that can't consolidate
    /// away) are pinned to the floor; the remaining sectors shrink proportionally to make room, and
    /// the sectors are re-laid contiguously in arc order so neighbors actually step back.
    private func enforceMinimumSpans(_ slices: [_Slice], pieCircumference: CGFloat) -> [_Slice] {
        guard slices.count > 1 else { return slices }

        let ordered = slices.sorted { $0.touchFrom < $1.touchFrom }
        let n = ordered.count
        let total = ordered.reduce(0.0) { $0 + $1.value }
        guard total > 0 else { return slices }

        // A span must cover the min view size plus the padding that the inset later carves out.
        let minSpan = (minSliceViewSize + paddingPoints) / pieCircumference

        // Not enough circle for everyone's minimum — fall back to equal spans.
        guard Double(n) * minSpan < 1.0 else {
            return reassign(ordered, spans: Array(repeating: 1.0 / Double(n), count: n))
        }

        var pinned = Array(repeating: false, count: n)
        var spans = Array(repeating: 0.0, count: n)
        while true {
            let pinnedCount = pinned.filter { $0 }.count
            let remaining = 1.0 - Double(pinnedCount) * minSpan
            let freeValueSum = (0..<n).reduce(0.0) { pinned[$1] ? $0 : $0 + ordered[$1].value }
            guard remaining > 0, freeValueSum > 0 else {
                spans = Array(repeating: 1.0 / Double(n), count: n)
                break
            }
            for i in 0..<n {
                spans[i] = pinned[i] ? minSpan : (ordered[i].value / freeValueSum) * remaining
            }
            // Pin any free sector that fell below the floor and iterate; otherwise we've converged.
            var newlyPinned = false
            for i in 0..<n where !pinned[i] && spans[i] < minSpan {
                pinned[i] = true
                newlyPinned = true
            }
            if !newlyPinned { break }
        }

        return reassign(ordered, spans: spans)
    }

    /// Re-lays sectors contiguously around the circle using the given per-sector spans, preserving
    /// arc order. `from`/`to` are placeholders here; `insetArc` recomputes them afterward.
    private func reassign(_ ordered: [_Slice], spans: [Double]) -> [_Slice] {
        var cumulative = 0.0
        return zip(ordered, spans).map { slice, span in
            let touchFrom = cumulative
            cumulative += span
            return .init(
                index: slice.index,
                kind: slice.kind,
                name: slice.name,
                sfSymbol: slice.sfSymbol,
                value: slice.value,
                touchFrom: touchFrom,
                touchTo: cumulative,
                from: slice.from,
                to: slice.to
            )
        }
    }

    /// Recomputes a sector's visible `from`/`to` from its touch range, insetting each end by half
    /// the padding plus the round-cap radius. Collapses to a point if the sector is too small to
    /// inset (rather than letting `from > to` wrap into a full-circle arc).
    private func insetArc(_ slice: _Slice, pieCircumference: CGFloat) -> _Slice {
        let padding = paddingPoints / pieCircumference
        let lineCap = (lineWidth / 2) / pieCircumference
        let rawFrom = slice.touchFrom + lineCap + (padding / 2)
        let rawTo = slice.touchTo - lineCap - (padding / 2)
        let midpoint = (slice.touchFrom + slice.touchTo) / 2

        // A slice too thin to inset (an un-mergeable lone sliver) would give `from > to`, which
        // `trim` wraps the long way into a huge wrong arc. Rather than collapse it to an invisible
        // point, render a `minSliceViewSize` lozenge centered on its midpoint so it stays visible.
        let from: CGFloat
        let to: CGFloat
        if rawFrom <= rawTo {
            from = rawFrom
            to = rawTo
        } else {
            let halfFloor = ((minSliceViewSize - lineWidth) / 2) / pieCircumference
            from = midpoint - halfFloor
            to = midpoint + halfFloor
        }

        return .init(
            index: slice.index,
            kind: slice.kind,
            name: slice.name,
            sfSymbol: slice.sfSymbol,
            value: slice.value,
            touchFrom: slice.touchFrom,
            touchTo: slice.touchTo,
            from: from,
            to: to
        )
    }
    
    private var grossTotal: Double { slicesState.reduce(0, { $0 + $1.value }) }
    
    private var netTotal: Double {
        slicesState.reduce(0, { $0 + (($1.kind == .income) ? $1.value : -$1.value) })
    }
    
    private func onTouchMoved(_ point: CGPoint, in frame: CGRect, slices: [_Slice]) {
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let fraction: CGFloat = {
            var angle = angleBetween(center: center, point: point)
            angle += 90 // Take chart rotation into accoun
            angle = angle > 360 ? angle - 360 : angle
            return angle / 360
        }()
        
        let selectedSlice = slices.first { $0.touchFrom <= fraction && $0.touchTo >= fraction }
        
        if touchStart == nil || self.selectedSlice?.id != selectedSlice?.id {
            touchStart = .now
        }
        
        withAnimation(.snappy) {
            self.selectedSlice = selectedSlice
        }
    }
    
    private func onTouchEnded() {
        if let touchStart = touchStart {
            let interval = Date.now.timeIntervalSince(touchStart)
            if interval < tapMaxDuration {
                return
            }
        }
        
        withAnimation(.snappy) {
            touchStart = nil
            selectedSlice = nil
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let pieRadius = min(geo.size.width, geo.size.height) / 2
            let pieCircumference = min(geo.size.width, geo.size.height) * Double.pi

            let slices = makeSlices(pieCircumference: pieCircumference)
            
            ZStack {
                Labels()
                if slices.isEmpty {
                    NoSlicesCircle()
                } else if slices.count == 1 {
                    SingleSliceView(slices.first!, radius: pieRadius)
                } else {
                    ZStack {
                        ForEach(slices) { slice in
                            SliceView(slice, radius: pieRadius)
                        }
                    }
                    .onTouchGesture { point in
                        onTouchMoved(point, in: geo.frame(in: .local), slices: slices)
                    } onTouchEnded: {
                        onTouchEnded()
                    }
                }
            }
            .foregroundStyle(Color.appText)
        }
        .padding(lineWidth / 2)
        .aspectRatio(1, contentMode: .fit)
        .onChange(of: slices, initial: true) { _, slices in
            slicesState = slices
            selectedSlice = nil
        }
    }
    
    private var textLabelString: String {
        if (slices.reduce(into: Set<Transaction.Category>()) { set, slice in set.insert(slice.category) }).count == 1 {
            return slices.first!.category.name.value
        }
        if let selectedSlice = selectedSlice {
            return selectedSlice.name
        }
        return String(localized: "Net Total")
    }
    
    private var selectedSliceSymbol: String {
        if (slices.reduce(into: Set<Transaction.Category>()) { set, slice in set.insert(slice.category) }).count == 1 {
            return slices.first!.category.name.value
        }
        if let selectedSlice = selectedSlice {
            return selectedSlice.sfSymbol.value
        }
        return ""
    }
    
    @ViewBuilder private func Labels() -> some View {
        VStack {
            if selectedSliceSymbol.isEmpty {
                Text(textLabelString)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .opacity(0)
                    .frame(width: 20, height: 16)
            } else {
                Image(systemName: selectedSliceSymbol)
                    .font(.title2.weight(.semibold))
                    .frame(width: 20, height: 16)
                    .transition(.symbolEffect)
            }
            Text("\(formatValue(selectedSlice == nil ? netTotal : selectedSlice!.value))")
                .font(.largeTitle.weight(.bold))
                .contentTransition(.numericText())
            Text(textLabelString)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder private func NoSlicesCircle() -> some View {
        Circle()
            .stroke(style: .init(
                lineWidth: lineWidth,
                lineCap: .round
            ))
            .foregroundStyle(Color.brandTeal)
            .opacity(0.5)
    }
    
    @ViewBuilder private func SingleSliceView(_ slice: _Slice, radius: CGFloat) -> some View {
        Circle()
            .stroke(style: .init(
                lineWidth: lineWidth,
                lineCap: .round
            ))
            .foregroundStyle(Color.brandTeal)
            .overlay {
                if slice.kind == .expense {
                    Circle()
                        .stroke(style: .init(
                            lineWidth: lineWidth - .borderWidthMedium,
                            lineCap: .round
                        ))
                        .foregroundStyle(Color.appBackground)
                }
            }
            .overlay {
                SliceIconView(slice, radius: radius, isDimmed: false)
                    .rotationEffect(.degrees(180))
            }
            .rotationEffect(.degrees(-90))
            .accessibilityIdentifier("PieChart.SingleSliceView.\(slice.name)")
    }
    
    @ViewBuilder private func SliceView(_ slice: _Slice, radius: CGFloat) -> some View {
        let isHighlighted = selectedSlice == nil || selectedSlice?.id == slice.id
        let isEnlarged = selectedSlice != nil && selectedSlice?.id == slice.id
        let isEnsmalled = selectedSlice != nil && selectedSlice?.id != slice.id
        
        let lineWidth = isEnlarged ? lineWidth + (paddingPoints / 2) : isEnsmalled ? lineWidth - (paddingPoints / 2) : lineWidth

        Circle()
            .trim(from: slice.from, to: slice.to)
            .stroke(style: .init(
                lineWidth: lineWidth,
                lineCap: .round
            ))
            .foregroundStyle(Color.brandTeal)
            .opacity(isHighlighted ? 1 : 0.5)
            .overlay {
                if slice.kind == .expense {
                    Circle()
                        .trim(from: slice.from, to: slice.to)
                        .stroke(style: .init(
                            lineWidth: lineWidth - .borderWidthMedium,
                            lineCap: .round
                        ))
                        .foregroundStyle(Color.appBackground)
                }
            }
            .overlay {
                SliceIconView(slice, radius: radius, isDimmed: isEnsmalled)
            }
            .rotationEffect(.degrees(-90))
            .accessibilityIdentifier("PieChart.SliceView.\(slice.name)")
    }
    
    @ViewBuilder private func SliceIconView(_ slice: _Slice, radius: CGFloat, isDimmed: Bool) -> some View {
        let degrees: Double = {
            let fraction = slice.from + ((slice.to - slice.from) / 2)
            return fraction * 360
        }()
        
        Image(systemName: slice.sfSymbol.value)
            .font(.system(size: lineWidth * 0.65))
            .bold()
            .foregroundStyle(slice.kind == .expense ? Color.appText : Color.appBackground)
            .frame(width: lineWidth, height: lineWidth)
            .scaleEffect(isDimmed ? 0.75 : 1)
            .opacity(isDimmed ? 0.5 : 1)
            .rotationEffect(.degrees(90))
            .offset(x: radius)
            .rotationEffect(.degrees(degrees))
    }
}

#Preview {
    PieChart(slices: PieChart.Slice.samples)
}

#Preview("Empty") {
    PieChart(slices: [])
}
