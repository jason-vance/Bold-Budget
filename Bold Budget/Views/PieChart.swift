//
//  PieChart.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import SwiftUI

struct PieChart: View {
    
    public struct Slice {
        let name: String
        let value: Double
        
        static let samples: [Slice] = [
            .init(name: "Groceries", value: 600),
            .init(name: "Housing", value: 2500),
            .init(name: "Travel", value: 1500),
            .init(name: "Entertainment", value: 250),
            .init(name: "Candy Bar", value: 5),
            .init(name: "Medical", value: 125)
        ]
    }
    
    private struct _Slice: Identifiable {
        var id: Int { index }
        let index: Int
        let name: String
        let value: Double
        let touchFrom: CGFloat
        let touchTo: CGFloat
        let from: CGFloat
        let to: CGFloat
    }

    private let lineWidth: CGFloat = 16
    private let tapMaxDuration: TimeInterval = 0.3
    private var minSliceViewSize: CGFloat  { 2 * lineWidth }
    
    @State var slices: [Slice]
    @State private var selectedSlice: _Slice? = nil
    @State private var touchStart: Date? = nil
    
    private var _color: Color = Color.black
    private var formatValue: (Double) -> String
    
    init(slices: [Slice]) {
        self.slices = slices
        self._color = Color.black
        formatValue = { value in value.formatted() }
    }
    
    func color(_ color: Color) -> PieChart {
        var view = self
        view._color = color
        return view
    }
    
    func valueFormatter(_ formatValue: @escaping (Double) -> String) -> PieChart {
        var view = self
        view.formatValue = formatValue
        return view
    }
    
    private func mapSlicesTo_Slice(pieCircumference: CGFloat) -> [_Slice] {
        let padding = CGFloat.padding / pieCircumference
        let lineCap = (lineWidth / 2) / pieCircumference
         
        var index = -1
        var previousCumulativeValue: CGFloat = 0
        return slices
            .sorted { $0.value < $1.value }
            .map { slice in
                let touchFrom = (previousCumulativeValue / total)
                let touchTo = touchFrom + (slice.value / total)
                let from = touchFrom + lineCap + (padding / 2)
                let to = touchTo - lineCap - (padding / 2)
                
                previousCumulativeValue += slice.value
                index += 1
                
                return .init(
                    index: index,
                    name: slice.name,
                    value: slice.value,
                    touchFrom: touchFrom,
                    touchTo: touchTo,
                    from: from,
                    to: to
                )
            }
    }
    
    private func mergeSmallSlicesIfNecessary(_ slices: [_Slice], pieCircumference: CGFloat) -> [_Slice] {
        let wontBeVisible: (_Slice) -> Bool = { slice in
            let length = (slice.touchTo - slice.touchFrom) * pieCircumference
            return length < (lineWidth + CGFloat.padding)
        }
        
        let merge: (_Slice, _Slice) -> _Slice = { lhs, rhs in
                .init(
                    index: min(lhs.index, rhs.index),
                    name: "\(rhs.name), \(lhs.name)",
                    value: lhs.value + rhs.value,
                    touchFrom: min(lhs.touchFrom, rhs.touchFrom),
                    touchTo: max(lhs.touchTo, rhs.touchTo),
                    from: min(lhs.from, rhs.from),
                    to: max(lhs.to, rhs.to)
                )
        }
        
        var rv: [_Slice] = slices
        while let firstSlice = rv.first, wontBeVisible(firstSlice) {
            guard rv.count >= 2 else { break }
            
            let secondSlice = rv[1]
            let mergedSlice = merge(firstSlice, secondSlice)
            
            rv = Array(rv.dropFirst(2))
            rv.insert(mergedSlice, at: 0)
        }
        
        return rv
    }
    
    private func makeSlices(pieSize: CGSize) -> [_Slice] {
        let pieCircumference = min(pieSize.width, pieSize.height) * Double.pi
        let slices = mapSlicesTo_Slice(pieCircumference: pieCircumference)
        return mergeSmallSlicesIfNecessary(slices, pieCircumference: pieCircumference)
    }
    
    private var total: Double { slices.reduce(0, { $0 + $1.value }) }
    
    var body: some View {
        GeometryReader { geo in
            let slices = makeSlices(pieSize: geo.size)
            
            ZStack {
                ZStack {
                    ForEach(slices) { slice in
                        SliceView(slice)
                    }
                }
                .onTouchGesture { point in
                    let center = CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY)
                    let angle = angleBetween(center: center, point: point)
                    let fraction = angle / 360
                    let selectedSlice = slices.first { $0.touchFrom <= fraction && $0.touchTo >= fraction }
                    
                    if touchStart == nil || self.selectedSlice?.id != selectedSlice?.id {
                        touchStart = .now
                    }
                    
                    withAnimation(.snappy) {
                        self.selectedSlice = selectedSlice
                    }
                } onTouchEnded: {
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
                VStack {
                    Text("Total")
                        .font(.title2.weight(.semibold))
                        .opacity(0)
                    Text("\(formatValue(selectedSlice == nil ? total : selectedSlice!.value))")
                        .font(.largeTitle.weight(.bold))
                        .contentTransition(.numericText())
                    Text(selectedSlice == nil ? "Total" : "\(selectedSlice!.name)")
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                }
            }
            .foregroundStyle(_color)
        }
        .padding(lineWidth / 2)
        .aspectRatio(1, contentMode: .fit)
    }
    
    @ViewBuilder private func SliceView(_ slice: _Slice) -> some View {
        let isHighlighted = selectedSlice == nil || selectedSlice?.id == slice.id
        let isEnlarged = selectedSlice != nil && selectedSlice?.id == slice.id
        let isEnsmalled = selectedSlice != nil && selectedSlice?.id != slice.id

        Circle()
            .trim(from: slice.from, to: slice.to)
            .stroke(style: .init(
                lineWidth: isEnlarged ? lineWidth + (.padding / 2) : isEnsmalled ? lineWidth - (.padding / 2) : lineWidth,
                lineCap: .round
            ))
            .foregroundStyle(_color)
            .opacity(isHighlighted ? 1 : 0.5)
    }
}

#Preview {
    PieChart(slices: PieChart.Slice.samples)
        .color(Color.blue)
}
