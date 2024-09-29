//
//  PieChart.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import SwiftUI

struct PieChart: View {
    
    private let colors: [Color] = [.red, .yellow, .blue, .purple, .orange, .green]
    
    public struct Slice {
        let name: String
        let value: Double
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
    
    private func makeSlices(pieSize: CGSize) -> [_Slice] {
        let pieCircumference = min(pieSize.width, pieSize.height) * Double.pi
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
    
    private var total: Double { slices.reduce(0, { $0 + $1.value }) }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                let slices = makeSlices(pieSize: geo.size)
                ForEach(slices) { slice in
                    SliceView(slice)
                }
            }
        }
        .padding(lineWidth / 2)
    }
    
    @ViewBuilder private func SliceView(_ slice: _Slice) -> some View {
        Circle()
            .trim(from: slice.from, to: slice.to)
            .rotation(.degrees(-90))
            .stroke(colors[slice.index], style: .init(lineWidth: lineWidth, lineCap: .round))
    }
}

#Preview {
    let slices: [PieChart.Slice] = [
        .init(name: "Groceries", value: 600),
        .init(name: "Housing", value: 2500),
        .init(name: "Travel", value: 1500),
        .init(name: "Entertainment", value: 250),
        .init(name: "Candy Bar", value: 5),
        .init(name: "Medical", value: 125)
    ]
    
    PieChart(slices: slices)
}
