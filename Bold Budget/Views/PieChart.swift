//
//  PieChart.swift
//  Bold Budget
//
//  Created by Jason Vance on 9/28/24.
//

import SwiftUI

struct PieChart: View {
    
    private let colors: [Color] = [.red, .yellow, .blue, .purple, .orange, .green]
    
    private struct Slice: Identifiable {
        var id: Int { index }
        let index: Int
        let value: Double
        let previousCumulativeValue: Double
    }
    
    private let lineWidth: CGFloat = 16
    private var minSliceViewSize: CGFloat  { 2 * lineWidth }
    
    @State private var pieces: [Slice] = [
        .init(
            index: 0,
            value: 500,
            previousCumulativeValue: 0
        ),
        .init(
            index: 1,
            value: 400,
            previousCumulativeValue: 500
        ),
        .init(
            index: 2,
            value: 300,
            previousCumulativeValue: 900
        ),
        .init(
            index: 3,
            value: 200,
            previousCumulativeValue: 1200
        ),
        .init(
            index: 4,
            value: 10,
            previousCumulativeValue: 1400
        ),
    ]
    
    private var sortedSlices: [Slice] {
        pieces.sorted { $0.index < $1.index }
    }
    
    private var total: Double { pieces.reduce(0, { $0 + $1.value }) }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(sortedSlices) { slice in
                    SliceView(slice, pieSize: geo.size)
                }
            }
        }
        .padding(lineWidth / 2)
    }
    
    @ViewBuilder private func SliceView(_ slice: Slice, pieSize: CGSize) -> some View {
        let pieCircumference = min(pieSize.width, pieSize.height) * Double.pi
        let padding = CGFloat.padding / pieCircumference
        let lineCap = (lineWidth / 2) / pieCircumference
        
        let from = (slice.previousCumulativeValue / total) + lineCap + (padding / 2)
        let to = from + (slice.value / total) - (2 * lineCap) - (padding / 2)
        Circle()
            .trim(from: from, to: to)
            .rotation(.degrees(-90))
            .stroke(colors[slice.index], style: .init(lineWidth: lineWidth, lineCap: .round))
    }
}

#Preview {
    PieChart()
}
