//
//  TimeFramePicker.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/3/24.
//

import SwiftUI

struct TimeFramePicker: View {
    
    @StateObject var budget: Budget
    @Binding var timeFrame: TimeFrame
    
    @State private var period: TimeFrame.Period = .month
    @State private var year: Int = SimpleDate.now.year
    @State private var month: Int = SimpleDate.now.month
    @State private var day: Int = SimpleDate.now.day

    private func setState(_ timeFrame: TimeFrame) {
        period = timeFrame.period
        year = timeFrame.start.year
        month = (period != .year) ? timeFrame.start.month : SimpleDate.now.month
        day = (period == .week) ? timeFrame.start.day : SimpleDate.now.day
    }
    
    private func setTimeFrame(period: TimeFrame.Period, year: Int, month: Int, day: Int) {
        guard let date = SimpleDate(year: year, month: month, day: day) else { return }
        timeFrame = .init(period: period, containing: date)
    }
    
    private var oldestTransactionDate: SimpleDate {
        guard let oldestTransaction = (budget.transactions.values.min { $0.date < $1.date }) else { return .now }
        return oldestTransaction.date
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
        .onChange(of: timeFrame) { _, timeFrame in setState(timeFrame) }
        .onChange(of: period) { _, period in setTimeFrame(period: period, year: year, month: month, day: day) }
        .onChange(of: year) { _, year in setTimeFrame(period: period, year: year, month: month, day: day) }
        .onChange(of: month) { _, month in setTimeFrame(period: period, year: year, month: month, day: day) }
    }
    
    @ViewBuilder func PeriodPicker() -> some View {
        HStack(spacing: .padding) {
            PeriodButton(.week)
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
                    ForEach((oldestTransactionDate.year...SimpleDate.now.year).map { $0 }, id: \.self) { year in
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
    
    @ViewBuilder func WeekPicker() -> some View {
        let weekDates = {
            var weekDates = stride(from: 1, to: 31, by: 7)
                .compactMap { day in
                    if let date = SimpleDate(year: year, month: month, day: day) {
                        return SimpleDate.startOfWeek(containing: date)
                    }
                    return nil
                }
            let monthEnd = SimpleDate.endOfMonth(containing: SimpleDate(year: year, month: month, day: day)!)
            let hasLastDayOfMonth = weekDates.contains { date in
                let weekStart = SimpleDate.startOfWeek(containing: date)
                let weekEnd = SimpleDate.endOfWeek(containing: weekStart)
                return monthEnd >= weekStart && monthEnd <= weekEnd
            }
            if !hasLastDayOfMonth {
                weekDates.append(SimpleDate.startOfWeek(containing: monthEnd))
            }
            return weekDates
        }()
        
        let dayLabels = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("E")
            
            let firstDate = weekDates.first!.toDate()!
            return (0...6).map { day in
                let date = Calendar.current.date(byAdding: .day, value: day, to: firstDate)!
                return formatter.string(from: date)
            }
        }()
        
        VStack(spacing: .padding) {
            HStack {
                ForEach(dayLabels, id: \.self) { dayLabel in
                    Text(dayLabel)
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, .paddingHorizontalButtonSmall)
            .padding(.top, .paddingVerticalButtonSmall)
            ForEach(weekDates, id: \.self) { weekDate in
                WeekButton(weekDate)
            }
        }
        .padding(.horizontal, .padding)
    }
    
    @ViewBuilder func WeekButton(_ weekDate: SimpleDate) -> some View {
        let weekStart = SimpleDate.startOfWeek(containing: weekDate)
        let days = (0...6)
            .map { offset in
                let start = weekStart.toDate()!
                return Calendar.current.date(byAdding: .day, value: offset, to: start)!
            }
        let monthStart = SimpleDate.startOfMonth(containing: SimpleDate(year: year, month: month, day: 1)!)
        let monthEnd = SimpleDate.endOfMonth(containing: monthStart)

        Button {
            withAnimation(.snappy) {
                setTimeFrame(period: period, year: weekStart.year, month: weekStart.month, day: weekStart.day)
            }
        } label: {
            HStack {
                ForEach(days, id: \.self) { day in
                    let isInCurrentMonth: Bool = day >= monthStart.toDate()! && day <= monthEnd.toDate()!
                    
                    Text(SimpleDate(date: day)!.day.formatted())
                        .frame(maxWidth: .infinity)
                        .font(isInCurrentMonth ? .body : .footnote)
                        .bold(isInCurrentMonth)
                }
            }
            .buttonLabelSmall(isProminent: days.contains(timeFrame.start.toDate()!))
        }
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
            if period != .year {
                BarDivider()
                MonthPicker()
                if period != .month {
                    BarDivider()
                    WeekPicker()
                }
            }
        }
    }
}

#Preview {
    StatefulPreviewContainer(TimeFrame.init(period: .month, containing: .now)) { timeFrame in
        VStack {
            TimeFramePicker(
                budget: Budget(info: .sample),
                timeFrame: timeFrame
            )
            Text(timeFrame.wrappedValue.toUiString())
        }
    }
}
