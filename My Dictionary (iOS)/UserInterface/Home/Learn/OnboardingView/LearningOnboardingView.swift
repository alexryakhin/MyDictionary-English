//
//  LearningOnboardingView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct LearningOnboardingView: View {
    @StateObject private var viewModel = LearningOnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Bar
                    progressBar
                    
                    // Content
                    TabView(selection: $viewModel.currentScreen) {
                        ForEach(LearningOnboardingScreen.allCases, id: \.self) { screen in
                            screenView(for: screen)
                                .tag(screen)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentScreen)
                    
                    // Navigation Buttons
                    navigationButtons
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Any setup when view appears
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text(Loc.Learning.Progress.stepOf(viewModel.currentScreenIndex, viewModel.totalScreens))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(Loc.Learning.Progress.progress)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: viewModel.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .accent))
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back Button
            if !viewModel.isFirstScreen {
                ActionButton(
                    Loc.Learning.CommonActions.back,
                    systemImage: "arrow.left.circle.fill",
                    style: .bordered
                ) {
                    viewModel.previousScreen()
                }
            }
            
            // Next/Continue Button
            AsyncActionButton(
                buttonTitle,
                systemImage: buttonIcon,
                style: .borderedProminent
            ) {
                if viewModel.isLastScreen {
                    await viewModel.completeOnboarding()
                    dismiss()
                } else {
                    viewModel.nextScreen()
                }
            }
            .disabled(!viewModel.canProceed || viewModel.isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var buttonTitle: String {
        if viewModel.isLoading {
            return "Loading..."
        } else if viewModel.isLastScreen {
            return Loc.Learning.CommonActions.finish
        } else {
            return Loc.Learning.CommonActions.next
        }
    }
    
    private var buttonIcon: String {
        if viewModel.isLastScreen {
            return "checkmark.circle.fill"
        } else {
            return "arrow.right.circle.fill"
        }
    }
    
    // MARK: - Screen Views
    
    @ViewBuilder
    private func screenView(for screen: LearningOnboardingScreen) -> some View {
        switch screen {
        case .welcome:
            WelcomeOnboardingScreen()
        case .targetLanguage:
            TargetLanguageOnboardingScreen(viewModel: viewModel)
        case .currentLevel:
            CurrentLevelOnboardingScreen(viewModel: viewModel)
        case .interests:
            InterestsOnboardingScreen(viewModel: viewModel)
        case .learningGoals:
            LearningGoalsOnboardingScreen(viewModel: viewModel)
        case .timeCommitment:
            TimeCommitmentOnboardingScreen(viewModel: viewModel)
        case .learningStyle:
            LearningStyleOnboardingScreen(viewModel: viewModel)
        case .nativeLanguage:
            NativeLanguageOnboardingScreen(viewModel: viewModel)
        case .motivation:
            MotivationOnboardingScreen(viewModel: viewModel)
        case .summary:
            SummaryOnboardingScreen(viewModel: viewModel)
        }
    }
}


#Preview {
    LearningOnboardingView()
}
