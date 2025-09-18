//
//  LearnMainViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import Combine
import SwiftUI

final class LearnMainViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var userProfile: LearningProfile?
    @Published var todaysStats = DailyStats()
    @Published var todaysLessons: [Lesson] = []
    @Published var recommendations: [Recommendation] = []
    @Published var weeklyProgress: [DailyProgress] = []
    @Published var learningStreak = 7
    @Published var totalWordsLearned = 247
    @Published var totalLessonsCompleted = 34
    @Published var totalStudyHours = 12
    
    // MARK: - Computed Properties
    
    var welcomeMessage: String {
        guard let profile = userProfile else {
            return "Welcome to Learning!"
        }
        
        let timeOfDay = getTimeOfDay()
        let name = "there" // In real app, would use user's name
        
        return "\(timeOfDay), \(name)!"
    }
    
    var learningGoalDescription: String {
        guard let profile = userProfile else {
            return "Start your personalized learning journey"
        }
        
        let targetLanguage = profile.targetLanguage.displayName
        let currentLevel = profile.currentLevel.displayName
        
        return "Learning \(targetLanguage) • \(currentLevel) Level"
    }
    
    var nextLevelProgress: NextLevelProgress? {
        guard let profile = userProfile else { return nil }
        
        let currentLevel = profile.currentLevel
        let nextLevel = getNextLevel(from: currentLevel)
        let progress = calculateLevelProgress()
        
        return NextLevelProgress(
            currentLevel: currentLevel,
            nextLevel: nextLevel,
            progress: progress
        )
    }
    
    // MARK: - Public Methods
    
    func loadUserProfile() {
        // Load from UserDefaults (demo implementation)
        if let data = UserDefaults.standard.data(forKey: "learning_profile"),
           let profile = try? JSONDecoder().decode(LearningProfile.self, from: data) {
            self.userProfile = profile
            generatePersonalizedContent()
        } else {
            // No profile found, show default content
            generateDefaultContent()
        }
    }
    
    // MARK: - Private Methods
    
    private func getTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    private func getNextLevel(from currentLevel: LanguageLevel) -> LanguageLevel {
        switch currentLevel {
        case .beginner: return .elementary
        case .elementary: return .intermediate
        case .intermediate: return .upperIntermediate
        case .upperIntermediate: return .advanced
        case .advanced: return .native
        case .native: return .native // Already at highest level
        }
    }
    
    private func calculateLevelProgress() -> Double {
        // Mock progress calculation
        return Double.random(in: 0.3...0.9)
    }
    
    private func generatePersonalizedContent() {
        guard let profile = userProfile else { return }
        
        // Generate personalized lessons based on user profile
        todaysLessons = generatePersonalizedLessons(for: profile)
        
        // Generate personalized recommendations
        recommendations = generatePersonalizedRecommendations(for: profile)
        
        // Generate weekly progress (mock data)
        weeklyProgress = DailyProgress.sampleData
        
        // Update stats based on user's time commitment
        updateStatsForTimeCommitment(profile.timeCommitment)
    }
    
    private func generateDefaultContent() {
        todaysLessons = generateDefaultLessons()
        recommendations = generateDefaultRecommendations()
        weeklyProgress = DailyProgress.sampleData
    }
    
    private func generatePersonalizedLessons(for profile: LearningProfile) -> [Lesson] {
        var lessons: [Lesson] = []
        
        // Base lessons on user's goals and interests
        if profile.learningGoals.contains(.travel) {
            lessons.append(Lesson(
                title: "Travel Essentials",
                description: "Learn essential phrases for traveling and navigating new places",
                iconName: "airplane",
                color: .blue,
                duration: profile.timeCommitment.minutesPerDay / 2,
                difficulty: profile.currentLevel == .beginner ? .beginner : .intermediate,
                isCompleted: false,
                category: .conversation
            ))
        }
        
        if profile.learningGoals.contains(.business) {
            lessons.append(Lesson(
                title: "Business Communication",
                description: "Professional phrases and vocabulary for business settings",
                iconName: "briefcase.fill",
                color: .green,
                duration: profile.timeCommitment.minutesPerDay,
                difficulty: profile.currentLevel == .beginner ? .intermediate : .advanced,
                isCompleted: false,
                category: .conversation
            ))
        }
        
        // Add vocabulary lesson based on interests
        if profile.interests.contains(where: { $0.category == .food }) {
            lessons.append(Lesson(
                title: "Food & Dining",
                description: "Vocabulary and phrases for restaurants, cooking, and food",
                iconName: "fork.knife",
                color: .orange,
                duration: profile.timeCommitment.minutesPerDay / 3,
                difficulty: profile.currentLevel == .beginner ? .beginner : .intermediate,
                isCompleted: false,
                category: .vocabulary
            ))
        }
        
        // Add grammar lesson based on current level
        lessons.append(Lesson(
            title: getGrammarLessonTitle(for: profile.currentLevel),
            description: getGrammarLessonDescription(for: profile.currentLevel),
            iconName: "textformat.abc",
            color: .purple,
            duration: profile.timeCommitment.minutesPerDay / 2,
            difficulty: profile.currentLevel == .beginner ? .beginner : .intermediate,
            isCompleted: false,
            category: .grammar
        ))
        
        return lessons
    }
    
    private func generatePersonalizedRecommendations(for profile: LearningProfile) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Generate recommendations based on user's interests
        for interest in profile.interests.prefix(3) {
            recommendations.append(Recommendation(
                title: getRecommendationTitle(for: interest),
                description: getRecommendationDescription(for: interest),
                iconName: interest.iconName,
                color: getColorForInterest(interest),
                category: .vocabulary,
                reason: "Based on your interest in \(interest.category.displayName.lowercased())"
            ))
        }
        
        // Add goal-based recommendations
        if profile.learningGoals.contains(.exam) {
            recommendations.append(Recommendation(
                title: "Exam Preparation",
                description: "Structured lessons to help you prepare for your language exam",
                iconName: "graduationcap.fill",
                color: .blue,
                category: .grammar,
                reason: "Matches your exam goal"
            ))
        }
        
        return recommendations
    }
    
    private func generateDefaultLessons() -> [Lesson] {
        return [
            Lesson(
                title: "Basic Greetings",
                description: "Learn essential greetings and polite expressions",
                iconName: "hand.wave.fill",
                color: .blue,
                duration: 15,
                difficulty: .beginner,
                isCompleted: false,
                category: .conversation
            ),
            Lesson(
                title: "Common Vocabulary",
                description: "Essential words for daily conversations",
                iconName: "book.fill",
                color: .green,
                duration: 20,
                difficulty: .beginner,
                isCompleted: false,
                category: .vocabulary
            )
        ]
    }
    
    private func generateDefaultRecommendations() -> [Recommendation] {
        return [
            Recommendation(
                title: "Start with Basics",
                description: "Begin your learning journey with fundamental vocabulary and grammar",
                iconName: "star.fill",
                color: .yellow,
                category: .vocabulary,
                reason: "Perfect for beginners"
            ),
            Recommendation(
                title: "Practice Speaking",
                description: "Improve your pronunciation with AI-powered speaking exercises",
                iconName: "mic.fill",
                color: .red,
                category: .pronunciation,
                reason: "Build confidence early"
            )
        ]
    }
    
    private func updateStatsForTimeCommitment(_ commitment: TimeCommitment) {
        switch commitment {
        case .casual:
            todaysStats = DailyStats(lessonsGoal: 2, wordsGoal: 10, timeGoal: 15)
        case .regular:
            todaysStats = DailyStats(lessonsGoal: 3, wordsGoal: 15, timeGoal: 25)
        case .intensive:
            todaysStats = DailyStats(lessonsGoal: 4, wordsGoal: 25, timeGoal: 40)
        case .intensivePlus:
            todaysStats = DailyStats(lessonsGoal: 6, wordsGoal: 40, timeGoal: 60)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getGrammarLessonTitle(for level: LanguageLevel) -> String {
        switch level {
        case .beginner: return "Basic Sentence Structure"
        case .elementary: return "Present Tense Verbs"
        case .intermediate: return "Past Tense Practice"
        case .upperIntermediate: return "Conditional Sentences"
        case .advanced: return "Complex Grammar Patterns"
        case .native: return "Advanced Grammar Review"
        }
    }
    
    private func getGrammarLessonDescription(for level: LanguageLevel) -> String {
        switch level {
        case .beginner: return "Learn how to form simple sentences and basic grammar rules"
        case .elementary: return "Master present tense verb conjugations and usage"
        case .intermediate: return "Practice past tense forms and irregular verbs"
        case .upperIntermediate: return "Learn conditional sentences and hypothetical situations"
        case .advanced: return "Study complex grammatical structures and nuances"
        case .native: return "Refine your understanding of advanced grammar concepts"
        }
    }
    
    private func getRecommendationTitle(for interest: LearningInterest) -> String {
        switch interest.category {
        case .lifestyle: return "Daily Life Vocabulary"
        case .technology: return "Tech & Digital Terms"
        case .entertainment: return "Movies & Entertainment"
        case .sports: return "Sports & Fitness"
        case .food: return "Food & Cooking"
        case .travel: return "Travel & Tourism"
        case .business: return "Business Vocabulary"
        case .education: return "Academic Terms"
        case .health: return "Health & Wellness"
        case .culture: return "Cultural Expressions"
        }
    }
    
    private func getRecommendationDescription(for interest: LearningInterest) -> String {
        switch interest.category {
        case .lifestyle: return "Essential words and phrases for everyday life and routines"
        case .technology: return "Modern technology terms and digital communication"
        case .entertainment: return "Vocabulary for movies, music, and entertainment"
        case .sports: return "Sports terminology and fitness-related vocabulary"
        case .food: return "Cooking terms, restaurant phrases, and food vocabulary"
        case .travel: return "Travel essentials, directions, and tourist vocabulary"
        case .business: return "Professional terms and business communication"
        case .education: return "Academic vocabulary and educational terminology"
        case .health: return "Medical terms and health-related vocabulary"
        case .culture: return "Cultural expressions and traditional phrases"
        }
    }
    
    private func getColorForInterest(_ interest: LearningInterest) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink, .teal, .indigo]
        return colors[abs(interest.id.hashValue) % colors.count]
    }
}

// MARK: - Supporting Models

struct DailyStats {
    let lessonsCompleted: Int
    let lessonsGoal: Int
    let wordsLearned: Int
    let wordsGoal: Int
    let minutesSpent: Int
    let timeGoal: Int
    
    init(lessonsCompleted: Int = 1, lessonsGoal: Int = 3, wordsLearned: Int = 8, wordsGoal: Int = 15, minutesSpent: Int = 18, timeGoal: Int = 25) {
        self.lessonsCompleted = lessonsCompleted
        self.lessonsGoal = lessonsGoal
        self.wordsLearned = wordsLearned
        self.wordsGoal = wordsGoal
        self.minutesSpent = minutesSpent
        self.timeGoal = timeGoal
    }
}

struct NextLevelProgress {
    let currentLevel: LanguageLevel
    let nextLevel: LanguageLevel
    let progress: Double
}
