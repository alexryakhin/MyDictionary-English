//
//  QuizActivityChart.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 1/8/25.
//

import SwiftUI
import Charts

// MARK: - Month Chart View

struct MonthChartView: View {

    enum MarkSize {
        case small
        case medium
        case large

        var width: MarkDimension {
            switch self {
            case .small:
                return 16
            case .medium:
                return 24
            case .large:
                return 32
            }
        }
    }

    struct ActivityData: Identifiable {
        let id = UUID()
        let date: Date
        let week: Int // y-axis (0-5 for 6 weeks)
        let day: Int // x-axis (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
        let quizCount: Int // Number of quizzes completed that day
    }

    let data: [ActivityData]
    let markSize: MarkSize
    let isCurrentMonth: Bool

    @State private var selectedX: Int?
    @State private var selectedY: Int?
    @State private var selectedActivity: ActivityData?

    private var maxQuizCount: Int {
        data.map(\.quizCount).max() ?? 1
    }

    private var weekCount: Int {
        data.map(\.week).max() ?? 0
    }

    var selectedActivityFromGrid: ActivityData? {
        guard let selectedX = selectedX, let selectedY = selectedY else { return nil }
        return data.first { $0.day == selectedX && (weekCount - $0.week) == selectedY }
    }

    var body: some View {
        if data.isEmpty {
            emptyStateView
        } else {
            activityChart(activities: data)
                .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text(Loc.Analytics.noQuizActivity)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            if isCurrentMonth {
                Text(Loc.Analytics.completeFirstQuizActivity)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func activityChart(activities: [ActivityData]) -> some View {
        Chart {
            // Activity squares
            ForEach(activities) { activity in
                RectangleMark(
                    x: .value("Day", activity.day),
                    y: .value("Week", weekCount - activity.week), // Invert Y so week 0 appears at top
                    width: markSize.width, // Increase mark size
                    height: markSize.width // Increase mark size
                )
                .foregroundStyle(color(for: activity.quizCount, maxCount: maxQuizCount))
                .cornerRadius(3)
                .opacity(
                    selectedX == nil && selectedY == nil
                    ? 1.0
                    : activity.day == selectedX && (weekCount - activity.week) == selectedY ? 1.0 : 0.3
                )
            }

            // RuleMark for both X and Y lines when dragging
            if let selectedActivity = selectedActivityFromGrid {
                // Vertical line (X-axis)
                RuleMark(x: .value("Selected Day", selectedActivity.day))
                    .foregroundStyle(.secondary)
                    .opacity(0.3)

                // Horizontal line (Y-axis)
                RuleMark(y: .value("Selected Week", weekCount - selectedActivity.week))
                    .foregroundStyle(.secondary)
                    .opacity(0.3)

                // Annotation at the intersection
                RectangleMark(
                    x: .value("Selected Day", selectedActivity.day),
                    y: .value("Selected Week", weekCount - selectedActivity.week),
                    width: markSize.width, // Fixed width for annotation point
                    height: markSize.width // Fixed height for annotation point
                )
                .foregroundStyle(.clear)
                .annotation(
                    position: .top,
                    overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                ) {
                    VStack(spacing: 4) {
                        Text(selectedActivity.date, format: .dateTime.month(.wide).day())
                            .font(.caption)
                            .fontWeight(.bold)

                        Text(Loc.Plurals.Analytics.quizzesCount(selectedActivity.quizCount))
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .lineLimit(1)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.accent.gradient)
                    )
                }
            }
        }
        .chartXScale(domain: -0.5...6.5) // Expand domain to prevent clipping
        .chartYScale(domain: -0.5...(Double(weekCount) + 0.5)) // Dynamic domain based on actual weeks
        .aspectRatio(1.4, contentMode: .fit) // Maintain proportional grid (7 days x dynamic weeks)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartXSelection(value: $selectedX)
        .chartYSelection(value: $selectedY)
        .animation(.easeInOut(duration: 0.2), value: selectedX)
        .animation(.easeInOut(duration: 0.2), value: selectedY)
        .onChange(of: selectedX) {
            if selectedX != nil {
                selectedActivity = selectedActivityFromGrid
                // Haptic feedback when selecting
                HapticManager.shared.triggerImpact(style: .light)
            } else {
                selectedActivity = nil
            }
        }
        .onChange(of: selectedY) {
            if selectedY != nil {
                selectedActivity = selectedActivityFromGrid
                // Haptic feedback when selecting
                HapticManager.shared.triggerImpact(style: .light)
            } else {
                selectedActivity = nil
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func color(for quizCount: Int, maxCount: Int) -> Color {
        if quizCount == 0 {
            return .gray.opacity(0.2)
        }

        // Calculate relative intensity based on the fraction of max quiz count
        let intensity = Double(quizCount) / Double(maxCount)

        // Map intensity to opacity: 0.3 to 1.0
        let opacity = 0.3 + (intensity * 0.7)

        return .accent.opacity(opacity)
    }
}

struct QuizActivityChart: View {

    let data: [MonthChartView.ActivityData]
    let onShowAllMonths: (() -> Void)?

    // MARK: - Computed Properties

    var currentMonthData: [MonthChartView.ActivityData] {
        let calendar = Calendar.current
        let currentMonth = Date()
        return data.filter { activity in
            calendar.isDate(activity.date, equalTo: currentMonth, toGranularity: .month)
        }
    }

    var previousMonthData: [MonthChartView.ActivityData] {
        let calendar = Calendar.current
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: Date()) else {
            return []
        }
        return data.filter { activity in
            calendar.isDate(activity.date, equalTo: previousMonth, toGranularity: .month)
        }
    }

    var previousMonthTitle: String {
        let calendar = Calendar.current
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: Date()) else {
            return ""
        }
        return previousMonth.formatted(.dateTime.month(.abbreviated).year())
    }

    var currentMonthTitle: String {
        Date().formatted(.dateTime.month(.abbreviated).year())
    }

    var body: some View {
        CustomSectionView(header: Loc.Analytics.quizActivity) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    // Previous month chart
                    VStack(alignment: .leading, spacing: 4) {
                        Text(previousMonthTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        MonthChartView(data: previousMonthData, markSize: .small, isCurrentMonth: false)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Current month chart
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentMonthTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        MonthChartView(data: currentMonthData, markSize: .small, isCurrentMonth: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                legendView
            }
        } trailingContent: {
            showAllButton
        }
    }

    // MARK: - Show All Button

    @ViewBuilder
    private var showAllButton: some View {
        if let onShowAllMonths {
            HeaderButton(
                Loc.Actions.viewAll,
                icon: "calendar",
                size: .small,
                action: onShowAllMonths
            )
        }
    }

    // MARK: - Legend View

    private var legendView: some View {
        HStack(spacing: 4) {
            Text(Loc.Analytics.less)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    Rectangle()
                        .fill(legendColor(for: index))
                        .frame(width: 8, height: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 1))
                }
            }

            Text(Loc.Analytics.more)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }

    private func legendColor(for index: Int) -> Color {
        let intensity = Double(index) / 4.0 // 0.0 to 1.0
        let opacity = 0.2 + (intensity * 0.8) // 0.2 to 1.0
        return .accent.opacity(opacity)
    }
}

#Preview {
    // Create sample data showing different activity levels for current and previous month
    var sampleData: [MonthChartView.ActivityData] {
        var data: [MonthChartView.ActivityData] = []
        let calendar = Calendar.current

        // Generate data for current month
        if let currentMonthInterval = calendar.dateInterval(of: .month, for: Date()) {
            var currentDate = currentMonthInterval.start
            while currentDate < currentMonthInterval.end {
                // Create a pattern: some days with activity, some without
                let dayOfMonth = calendar.component(.day, from: currentDate)
                let quizCount = (dayOfMonth % 3 == 0 || dayOfMonth % 5 == 0) ? Int.random(in: 1...8) : 0

                // Calculate grid coordinates for current month
                let dayOfWeek = calendar.component(.weekday, from: currentDate) - 1
                let firstDayOfMonth = currentMonthInterval.start
                let firstDayOfWeek = calendar.component(.weekday, from: firstDayOfMonth) - 1
                let calculatedWeek = (dayOfMonth - 1 + firstDayOfWeek) / 7
                let weekOfMonth = calculatedWeek // No inversion - first week is 0, last week is max

                data.append(MonthChartView.ActivityData(
                    date: currentDate,
                    week: weekOfMonth,
                    day: dayOfWeek,
                    quizCount: quizCount
                ))

                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }

        // Generate data for previous month
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: Date()),
           let previousMonthInterval = calendar.dateInterval(of: .month, for: previousMonth) {
            var currentDate = previousMonthInterval.start
            while currentDate < previousMonthInterval.end {
                // Create a pattern: some days with activity, some without
                let dayOfMonth = calendar.component(.day, from: currentDate)
                let quizCount = (dayOfMonth % 4 == 0 || dayOfMonth % 6 == 0) ? Int.random(in: 1...6) : 0

                // Calculate grid coordinates for previous month
                let dayOfWeek = calendar.component(.weekday, from: currentDate) - 1
                let firstDayOfMonth = previousMonthInterval.start
                let firstDayOfWeek = calendar.component(.weekday, from: firstDayOfMonth) - 1
                let calculatedWeek = (dayOfMonth - 1 + firstDayOfWeek) / 7
                let weekOfMonth = calculatedWeek // No inversion - first week is 0, last week is max

                data.append(MonthChartView.ActivityData(
                    date: currentDate,
                    week: weekOfMonth,
                    day: dayOfWeek,
                    quizCount: quizCount
                ))

                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }

        return data
    }

    return ScrollView {
        QuizActivityChart(
            data: sampleData,
            onShowAllMonths: { print("Show all months") }
        )
        .padding()
    }
}
