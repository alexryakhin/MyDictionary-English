//
//  AllQuizActivityView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 1/8/25.
//

import SwiftUI
import Combine

struct AllQuizActivityView: View {

    @StateObject private var viewModel = AllQuizActivityViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                spacing: 12
            ) {
                if viewModel.monthlyData.isEmpty {
                    ContentUnavailableView(
                        Loc.Analytics.noQuizActivity,
                        systemImage: "chart.bar.xaxis",
                        description: Text(Loc.Analytics.completeFirstQuizActivity)
                    )
                } else {
                    ForEach(viewModel.monthlyData, id: \.month) { monthData in
                        CustomSectionView(
                            header: monthData.monthTitle,
                            footer: Loc.Plurals.Analytics.quizzesCompletedThisMonth(monthData.data.reduce(0) { $0 + $1.quizCount })
                        ) {
                            MonthChartView(
                                data: monthData.data,
                                markSize: .small,
                                isCurrentMonth: monthData.isCurrentMonth
                            )
                            .padding(.bottom, 8)
                        }
                    }
                }
            }
            .padding(vertical: 12, horizontal: 16)
        }
        .groupedBackground()
        .navigation(
            title: Loc.Analytics.quizActivity,
            mode: .inline,
            showsBackButton: true
        )
        .onAppear {
            AnalyticsService.shared.logEvent(.quizActivityDetailOpened)
            viewModel.loadData()
        }
    }
}

// MARK: - View Model

final class AllQuizActivityViewModel: BaseViewModel {

    @Published private(set) var monthlyData: [MonthData] = []

    private let quizAnalyticsService = QuizAnalyticsService.shared
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        setupReactiveUpdates()
    }

    private func setupReactiveUpdates() {
        // Listen to Core Data changes
        CoreDataService.shared.dataUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &cancellables)

        // Listen to shared dictionary changes with debouncing to prevent excessive refreshes
        DictionaryService.shared.$sharedWords
            .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &cancellables)
    }

    func loadData() {
        let allQuizSessions = quizAnalyticsService.getQuizSessions()
        monthlyData = processMonthlyData(from: allQuizSessions)
    }

    private func processMonthlyData(from sessions: [CDQuizSession]) -> [MonthData] {
        let calendar = Calendar.current
        var monthlyDataMap: [Date: [MonthChartView.ActivityData]] = [:]

        // Group sessions by month
        for session in sessions {
            guard let sessionDate = session.date else { continue }
            let monthStart = calendar.dateInterval(of: .month, for: sessionDate)?.start ?? sessionDate

            if monthlyDataMap[monthStart] == nil {
                monthlyDataMap[monthStart] = []
            }
        }

        // Generate activity data for each month
        var result: [MonthData] = []
        let currentMonth = Date()

        for (monthStart, _) in monthlyDataMap.sorted(by: { $0.key < $1.key }) {
            let monthData = quizAnalyticsService.generateActivityDataForMonth(
                monthStart: monthStart,
                sessions: sessions
            )

            result.append(MonthData(
                month: monthStart,
                monthTitle: monthStart.formatted(.dateTime.month(.wide).year()),
                data: monthData,
                isCurrentMonth: calendar.isDate(monthStart, equalTo: currentMonth, toGranularity: .month)
            ))
        }

        return result
    }
}

// MARK: - Supporting Types

struct MonthData {
    let month: Date
    let monthTitle: String
    let data: [MonthChartView.ActivityData]
    let isCurrentMonth: Bool
}
