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
            // Period picker anchors the top; the more-granular sections reveal downward as the
            // timeframe narrows (year → month → week). Presented as a dropdown under the toolbar,
            // so the top stays fixed and only the bottom grows/shrinks when switching periods.
            PillSegmentedControl(
                selection: $period,
                options: [.week, .month, .year],
                title: { $0.toUiString() }
            )
            LabeledSection("Year") { YearPicker() }
            if period != .year {
                LabeledSection("Month") { MonthPicker() }
                    .transition(.opacity)
            }
            if period == .week {
                LabeledSection("Week") { WeekPicker() }
                    .transition(.opacity)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .top)
        .foregroundStyle(Color.appText)
        .onAppear { setState(timeFrame) }
        .onChange(of: timeFrame) { _, timeFrame in setState(timeFrame) }
        .onChange(of: period) { _, period in setTimeFrame(period: period, year: year, month: month, day: day) }
        .onChange(of: year) { _, year in setTimeFrame(period: period, year: year, month: month, day: day) }
        .onChange(of: month) { _, month in setTimeFrame(period: period, year: year, month: month, day: day) }
    }

    // MARK: - Reusable selectable pill

    @ViewBuilder private func Pill<Label: View>(isSelected: Bool, fill: Bool = true, @ViewBuilder label: () -> Label) -> some View {
        label()
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? .white : Color.appText)
            .frame(maxWidth: fill ? .infinity : nil)
            .padding(.vertical, .paddingVerticalButtonSmall)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                    .foregroundStyle(isSelected ? Color.brandTeal : Color.appSurface)
            }
    }

    private func SectionLabel(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .kerning(0.6)
            .foregroundStyle(Color.appMutedText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Year

    @ViewBuilder func YearPicker() -> some View {
        ScrollViewReader { value in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: .paddingSmall) {
                    ForEach((oldestTransactionDate.year...SimpleDate.now.year).map { $0 }, id: \.self) { year in
                        Button {
                            withAnimation(.snappy) {
                                self.year = year
                                value.scrollTo(year, anchor: .center)
                            }
                        } label: {
                            Pill(isSelected: year == self.year, fill: false) {
                                Text(String(year))
                                    .fixedSize()
                                    .padding(.horizontal, .padding)
                            }
                            .id(year)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .onAppear { value.scrollTo(year, anchor: .center) }
        }
        // A horizontal ScrollView is vertically flexible and collapses when space is tight (the
        // taller week form). Pin its height so the year pills always stay visible.
        .frame(height: .barHeight)
    }

    // MARK: - Month

    @ViewBuilder func MonthPicker() -> some View {
        VStack(spacing: .paddingSmall) {
            ForEach((0..<3).map { $0 }, id: \.self) { row in
                HStack(spacing: .paddingSmall) {
                    ForEach((0..<4).map { $0 }, id: \.self) { column in
                        MonthButton(row * 4 + column + 1)
                    }
                }
            }
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
            withAnimation(.snappy) { self.month = month }
        } label: {
            Pill(isSelected: month == self.month) { Text(text) }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Week

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

        VStack(spacing: .paddingSmall) {
            HStack(spacing: 0) {
                ForEach(dayLabels, id: \.self) { dayLabel in
                    Text(dayLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.appMutedText)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, .paddingSmall)
            ForEach(weekDates, id: \.self) { weekDate in
                WeekButton(weekDate)
            }
        }
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
        let isSelected = days.contains(timeFrame.start.toDate()!)

        Button {
            withAnimation(.snappy) {
                setTimeFrame(period: period, year: weekStart.year, month: weekStart.month, day: weekStart.day)
            }
        } label: {
            Pill(isSelected: isSelected) {
                HStack(spacing: 0) {
                    ForEach(days, id: \.self) { day in
                        let isInCurrentMonth: Bool = day >= monthStart.toDate()! && day <= monthEnd.toDate()!

                        Text(SimpleDate(date: day)!.day.formatted())
                            .frame(maxWidth: .infinity)
                            .font(isInCurrentMonth ? .subheadline.weight(.semibold) : .footnote)
                            .foregroundStyle(
                                isSelected ? .white
                                : isInCurrentMonth ? Color.appText : Color.appMutedText
                            )
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func LabeledSection<Content: View>(
        _ label: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: .paddingSmall) {
            SectionLabel(label)
            content()
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
