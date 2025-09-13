//
//  LearningOnboardingViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import Combine

final class LearningOnboardingViewModel: ObservableObject {
    
    // MARK: - Output
    
    enum Output {
        case showMainLearning
        case showOnboarding
        case onboardingCompleted
    }
    
    let output = PassthroughSubject<Output, Never>()
    
    // MARK: - Published Properties
    
    @Published var currentScreen: LearningOnboardingScreen = .welcome
    @Published var isAnimating = false
    @Published var isLoading = false
    
    // MARK: - Learning Profile Data
    
    @Published var targetLanguage: InputLanguage = .english
    @Published var currentLevel: LanguageLevel = .beginner
    @Published var selectedInterests: Set<LearningInterest> = []
    @Published var selectedGoals: Set<LearningGoal> = []
    @Published var timeCommitment: TimeCommitment = .casual
    @Published var learningStyle: LearningStyle = .balanced
    @Published var nativeLanguage: InputLanguage = .english
    @Published var motivation: LearningMotivation = .personal
    
    // MARK: - Available Data
    
    @Published var availableInterests: [LearningInterest] = LearningInterest.allInterests
    
    // MARK: - Computed Properties
    
    var canProceed: Bool {
        switch currentScreen {
        case .welcome:
            return true
        case .targetLanguage:
            return true // Always has a default
        case .currentLevel:
            return true // Always has a default
        case .interests:
            return true // Optional selection
        case .learningGoals:
            return !selectedGoals.isEmpty
        case .timeCommitment:
            return true // Always has a default
        case .learningStyle:
            return true // Always has a default
        case .nativeLanguage:
            return true // Always has a default
        case .motivation:
            return true // Always has a default
        case .summary:
            return true
        }
    }
    
    var progress: Double {
        let currentIndex = currentScreen.index
        let totalScreens = LearningOnboardingScreen.allCases.count
        return Double(currentIndex) / Double(totalScreens - 1)
    }
    
    var currentScreenIndex: Int {
        currentScreen.index + 1
    }
    
    var totalScreens: Int {
        LearningOnboardingScreen.allCases.count
    }
    
    var isFirstScreen: Bool {
        currentScreen == .welcome
    }
    
    var isLastScreen: Bool {
        currentScreen == .summary
    }
    
    // MARK: - Methods
    
    func nextScreen() {
        guard canProceed else { return }
        
        isAnimating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            let currentIndex = self.currentScreen.index
            let nextIndex = currentIndex + 1
            
            if nextIndex < LearningOnboardingScreen.allCases.count {
                self.currentScreen = LearningOnboardingScreen.allCases[nextIndex]
            }
            
            self.isAnimating = false
        }
    }
    
    func previousScreen() {
        guard !isFirstScreen else { return }
        
        isAnimating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            let currentIndex = self.currentScreen.index
            let previousIndex = currentIndex - 1
            
            if previousIndex >= 0 {
                self.currentScreen = LearningOnboardingScreen.allCases[previousIndex]
            }
            
            self.isAnimating = false
        }
    }
    
    func goToScreen(_ screen: LearningOnboardingScreen) {
        isAnimating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            self.currentScreen = screen
            self.isAnimating = false
        }
    }
    
    func toggleInterest(_ interest: LearningInterest) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
    }
    
    func toggleGoal(_ goal: LearningGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }
    
    func completeOnboarding() async {
        isLoading = true
        
        // Create learning profile
        let profile = LearningProfile(
            targetLanguage: targetLanguage,
            currentLevel: currentLevel,
            interests: Array(selectedInterests),
            learningGoals: Array(selectedGoals),
            timeCommitment: timeCommitment,
            learningStyle: learningStyle,
            nativeLanguage: nativeLanguage,
            motivation: motivation
        )
        
        // Save profile (you'll implement this)
        await saveLearningProfile(profile)
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.output.send(.onboardingCompleted)
        }
    }
    
    // MARK: - Private Methods
    
    private func saveLearningProfile(_ profile: LearningProfile) async {
        // TODO: Implement saving to Core Data or UserDefaults
        print("📚 Saving learning profile: \(profile)")
        
        // For now, just save to UserDefaults as a demo
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "learning_profile")
        }
    }
    
    // MARK: - Filtering Methods
    
    func filteredInterests(for category: InterestCategory) -> [LearningInterest] {
        return availableInterests.filter { $0.category == category }
    }
    
    func getInterestsCategories() -> [InterestCategory] {
        return InterestCategory.allCases
    }
}
