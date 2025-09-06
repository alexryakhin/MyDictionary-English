//
//  AnalyticsFlow.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct AnalyticsFlow: View {

    // MARK: - Properties

    @StateObject private var navigationManager: NavigationManager = .shared
    @ObservedObject var viewModel: AnalyticsViewModel

    // MARK: - Body

    var body: some View {
        AnalyticsContentView(viewModel: viewModel)
            .onReceive(viewModel.output) { output in
                handleOutput(output)
            }
    }

    // MARK: - Private Methods

    private func handleOutput(_ output: AnalyticsViewModel.Output) {
        switch output {
        case .showQuizResultsList:
            navigationManager.navigationPath.append(NavigationDestination.quizResultsList)
        case .showAllQuizActivity:
            navigationManager.navigationPath.append(NavigationDestination.allQuizActivity)
        }
    }
}
