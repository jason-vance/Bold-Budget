//
//  TimeFramePicker.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/3/24.
//

import SwiftUI

struct TimeFramePicker: View {
    
    @Binding var timeFrame: TimeFrame
    
    @State private var period: TimeFrame.Period = .month
    @State private var year: Int = SimpleDate.now.year
    @State private var month: Int = SimpleDate.now.month
    
    private func setState(_ timeFrame: TimeFrame) {
        period = timeFrame.period
        year = timeFrame.start.year
        month = timeFrame.start.month
    }
    
    private func setTimeFrame(period: TimeFrame.Period, year: Int, month: Int) {
        guard let date = SimpleDate(year: year, month: month, day: 1) else { return }
        timeFrame = .init(period: period, containing: date)
    }
    
    var body: some View {
        VStack(spacing: .padding) {
            PeriodPicker()
                .padding(.horizontal, .padding)
            BarDivider()
            YearAndMonthPicker()
        }
        .padding(.vertical, .padding)
        .background(Color.background)
        .onAppear { setState(timeFrame) }
        .onChange(of: period) { _, period in setTimeFrame(period: period, year: year, month: month) }
        .onChange(of: year) { _, year in setTimeFrame(period: period, year: year, month: month) }
        .onChange(of: month) { _, month in setTimeFrame(period: period, year: year, month: month) }
    }
    
    @ViewBuilder func PeriodPicker() -> some View {
        HStack(spacing: .padding) {
            PeriodButton(.month)
            PeriodButton(.year)
        }
    }
    
    @ViewBuilder func PeriodButton(_ period: TimeFrame.Period) -> some View {
        let isSelected = period == self.period
        Button {
            withAnimation(.snappy) { self.period = period }
        } label: {
            Text(period.toUiString())
                .frame(maxWidth: .infinity)
                .buttonLabelSmall(isProminent: isSelected)
        }
    }
    
    @ViewBuilder func YearPicker() -> some View {
        ScrollViewReader { value in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach((2016...SimpleDate.now.year).map { $0 }, id: \.self) { year in
                        Button {
                            withAnimation(.snappy) {
                                self.year = year
                                value.scrollTo(year, anchor: .center)
                            }
                        } label: {
                            Text(String(year))
                                .buttonLabelSmall(isProminent: year == self.year)
                                .id(year)
                        }
                    }
                }
                .padding(.horizontal, .padding)
            }
            .onAppear { value.scrollTo(year, anchor: .center) }
        }
        .frame(height: .barHeight)
    }
    
    @ViewBuilder func MonthPicker() -> some View {
        VStack(spacing: .padding) {
            ForEach((0..<3).map { $0 }, id: \.self) { row in
                HStack(spacing: .padding) {
                    ForEach((0..<4).map { $0 }, id: \.self) { column in
                        MonthButton(row * 4 + column + 1)
                    }
                }
            }
        }
        .padding(.horizontal, .padding)
    }
    
    @ViewBuilder func MonthButton(_ month: Int) -> some View {
        let text: String = {
            let reference = SimpleDate.startOfYear(containing: .now).toDate()!
            let date = Calendar.current.date(byAdding: .month, value: month - 1, to: reference)!
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }()

        Button {
            withAnimation(.snappy) {
                self.month = month
            }
        } label: {
            Text(text)
                .frame(maxWidth: .infinity)
                .buttonLabelSmall(isProminent: month == self.month)
        }
    }
    
    @ViewBuilder func YearAndMonthPicker() -> some View {
        VStack(spacing: .padding) {
            YearPicker()
            if period == .month {
                BarDivider()
                MonthPicker()
            }
        }
    }
}

#Preview {
    StatefulPreviewContainer(TimeFrame.init(period: .month, containing: .now)) { timeFrame in
        VStack {
            TimeFramePicker(timeFrame: timeFrame)
            Text(timeFrame.wrappedValue.toUiString())
        }
    }
}
