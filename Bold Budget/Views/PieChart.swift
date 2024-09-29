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
        let from: CGFloat
        let to: CGFloat
    }

    private let lineWidth: CGFloat = 16
    private var minSliceViewSize: CGFloat  { 2 * lineWidth }
    
    @State var slices: [Slice]
    
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
            .sorted { $0.value > $1.value }
            .map { slice in
                let from = (previousCumulativeValue / total) + lineCap + (padding / 2)
                let to = from + (slice.value / total) - (2 * lineCap) - (padding / 2)
                
                previousCumulativeValue += slice.value
                index += 1
                
                return .init(
                    index: index,
                    name: slice.name,
                    value: slice.value,
                    from: from,
                    to: to
                )
            }
    }
    
    private func mergeSmallSlicesIfNecessary(_ slices: [_Slice], pieCircumference: CGFloat) -> [_Slice] {
        let wontBeVisible: (_Slice) -> Bool = { slice in
            let length = (slice.to - slice.from) * pieCircumference
            print("pieCircumference: \(pieCircumference), length: \(length)")
            return length < (lineWidth / 2)
        }
        
        let merge: (_Slice, _Slice) -> _Slice = { lhs, rhs in
                .init(
                    index: min(lhs.index, rhs.index),
                    name: "\(lhs.name), \(rhs.name)",
                    value: lhs.value + rhs.value,
                    from: min(lhs.from, rhs.from),
                    to: max(lhs.to, rhs.to)
                )
        }
        
        var rv: [_Slice] = slices
        while let lastSlice = rv.last, wontBeVisible(lastSlice) {
            guard rv.count >= 2 else { break }
            
            let secondToLastSlice = rv[rv.count - 2]
            let mergedSlice = merge(lastSlice, secondToLastSlice)
            
            rv = rv.dropLast(2)
            rv.append(mergedSlice)
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
            ZStack {
                let slices = makeSlices(pieSize: geo.size)
                ForEach(slices) { slice in
                    SliceView(slice)
                }
                VStack {
                    Text("Total")
                        .font(.title2.weight(.semibold))
                        .opacity(0)
                    Text("\(formatValue(total))")
                        .font(.largeTitle.weight(.bold))
                    Text("Total")
                        .font(.title2.weight(.semibold))
                }
            }
            .foregroundStyle(_color)
        }
        .padding(lineWidth / 2)
    }
    
    @ViewBuilder private func SliceView(_ slice: _Slice) -> some View {
        Circle()
            .trim(from: slice.from, to: slice.to)
            .rotation(.degrees(-90))
            .stroke(style: .init(lineWidth: lineWidth, lineCap: .round))
            .foregroundStyle(_color)
    }
}

#Preview {
    PieChart(slices: PieChart.Slice.samples)
        .color(Color.blue)
}
