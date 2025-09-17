//
//  LearnFlow.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct LearnFlow: View {

    // MARK: - Properties

    @StateObject private var navigationManager: NavigationManager = .shared
    @StateObject private var learningOnboardingViewModel = LearningOnboardingViewModel()

    // MARK: - Body

    var body: some View {
        LearningTabView()
            .onReceive(learningOnboardingViewModel.output) { output in
                handleLearningOutput(output)
            }
    }

    // MARK: - Private Methods

    private func handleLearningOutput(_ output: LearningOnboardingViewModel.Output) {
        switch output {
        case .showMainLearning:
            // Navigate to main learning interface
            // This will be implemented when we add the main learning content
            break
        case .showOnboarding:
            // Show onboarding - this is handled by the LearningTabView
            break
        case .onboardingCompleted:
            // Handle onboarding completion
            // This will be implemented when we add the main learning content
            break
        }
    }
}
