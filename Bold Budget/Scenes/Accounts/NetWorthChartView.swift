//
//  NetWorthChartView.swift
//  Bold Budget
//
//  Created by Jason Vance on 7/21/26.
//

import SwiftUI

/// A compact area chart of net worth over time, driven by account snapshot history.
/// Hand-drawn to match the app's monochrome style (no external charting dependency).
struct NetWorthChartView: View {

    let history: [(date: SimpleDate, value: SignedMoney)]

    private var values: [Double] { history.map(\.value.amount) }

    var body: some View {
        VStack(alignment: .leading, spacing: .paddingSmall) {
            GeometryReader { geo in
                let points = points(in: geo.size)
                ZStack {
                    ZeroBaseline(in: geo.size)
                    AreaFill(points: points, height: geo.size.height)
                    LinePath(points: points)
                        .stroke(
                            Color.text,
                            style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )
                    if let last = points.last {
                        Circle()
                            .fill(Color.text)
                            .frame(width: 6, height: 6)
                            .position(last)
                    }
                }
            }
            .frame(height: 132)

            HStack {
                Text(endpointLabel(history.first))
                Spacer(minLength: 0)
                Text(endpointLabel(history.last))
            }
            .font(.caption2)
            .foregroundStyle(Color.text.opacity(.opacityMutedText))
        }
    }

    private func endpointLabel(_ item: (date: SimpleDate, value: SignedMoney)?) -> String {
        item?.date.toDate()?.toBasicUiString() ?? ""
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard !values.isEmpty else { return [] }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 0
        // Include zero in the range so the baseline is meaningful, and avoid a zero divisor.
        let low = Swift.min(minV, 0)
        let high = Swift.max(maxV, 0)
        let range = Swift.max(high - low, 1)

        return values.enumerated().map { index, value in
            let x = values.count == 1
                ? size.width / 2
                : size.width * CGFloat(index) / CGFloat(values.count - 1)
            let y = size.height - CGFloat((value - low) / range) * size.height
            return CGPoint(x: x, y: y)
        }
    }

    @ViewBuilder private func ZeroBaseline(in size: CGSize) -> some View {
        let minV = Swift.min(values.min() ?? 0, 0)
        let maxV = Swift.max(values.max() ?? 0, 0)
        let range = Swift.max(maxV - minV, 1)
        let y = size.height - CGFloat((0 - minV) / range) * size.height
        Path { path in
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }
        .stroke(Color.text.opacity(0.12), style: .init(lineWidth: 1, dash: [3, 3]))
    }

    private struct AreaFill: View {
        let points: [CGPoint]
        let height: CGFloat
        var body: some View {
            Path { path in
                guard let first = points.first else { return }
                path.move(to: CGPoint(x: first.x, y: height))
                path.addLine(to: first)
                for point in points.dropFirst() { path.addLine(to: point) }
                if let last = points.last {
                    path.addLine(to: CGPoint(x: last.x, y: height))
                }
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [Color.text.opacity(0.18), Color.text.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private struct LinePath: Shape {
        let points: [CGPoint]
        func path(in rect: CGRect) -> Path {
            Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() { path.addLine(to: point) }
            }
        }
    }
}

#Preview {
    NetWorthChartView(history: Account.samples.netWorthHistory())
        .padding()
        .background(Color.background)
        .foregroundStyle(Color.text)
}
