//
//  LearningModels.swift
//  My Dictionary
//
//  Created by AI Learning Development Team on 3/9/25.
//

import Foundation

// MARK: - Learning Models Namespace

/// Namespace for all learning system models to avoid global namespace conflicts
enum LearningModels {
    
    // MARK: - Learning Plan Models
    
    struct DailyStructure: Codable {
        let vocabulary: Int
        let grammar: Int
        let speaking: Int
        let writing: Int
        let reading: Int
    }
    
    struct WeeklyTheme: Codable {
        let week: Int
        let theme: String
        let vocabulary: Int
        let grammar: [String]
        let assessments: [String]
    }
    
    struct LearningAssessmentCheckpoint: Codable {
        let day: Int
        let type: String
        let criteria: LearningAssessmentCriteria
    }
    
    struct LearningAssessmentCriteria: Codable {
        let vocabulary: Int
        let grammar: Int
        let speaking: Int
        let writing: Int
    }
    
    struct LearningPlan: Codable {
        let id: String
        let targetLanguage: String
        let currentLevel: String
        let totalDuration: Int
        let dailyStructure: DailyStructure
        let weeklyThemes: [WeeklyTheme]
        let assessmentCheckpoints: [LearningAssessmentCheckpoint]
        let createdAt: Date
    }
    
    // MARK: - Lesson Models
    
    enum LessonType: String, CaseIterable, Codable {
        case vocabulary = "vocabulary"
        case grammar = "grammar"
        case speaking = "speaking"
        case writing = "writing"
        case reading = "reading"
    }
    
    enum LessonStatus: String, CaseIterable, Codable {
        case notStarted = "not_started"
        case inProgress = "in_progress"
        case completed = "completed"
        case skipped = "skipped"
    }
    
    struct LessonContent: Codable {
        let objectives: [String]
        let vocabulary: [VocabularyItem]?
        let grammar: GrammarContent?
        let exercises: [LessonExercise]
        let examples: [String]
        let culturalNotes: [String]?
    }
    
    struct VocabularyItem: Codable {
        let word: String
        let translation: String
        let pronunciation: String
        let example: String
        let memoryTip: String?
    }
    
    struct GrammarContent: Codable {
        let topic: String
        let explanation: String
        let rules: [String]
        let examples: [String]
        let commonMistakes: [String]?
    }
    
    struct LessonExercise: Codable {
        let type: String
        let question: String
        let options: [String]?
        let correct: String
        let explanation: String?
    }
    
    struct Lesson: Codable {
        let id: String
        let learningPlanId: String
        let type: LessonType
        let day: Int
        let week: Int
        let theme: String
        let title: String
        let content: LessonContent
        let estimatedDuration: Int
        let difficulty: String
        let status: LessonStatus
        let completedAt: Date?
        let timeSpent: Int
        let score: Float
        let createdAt: Date
    }
    
    // MARK: - Assessment Models
    
    enum AssessmentType: String, CaseIterable, Codable {
        case dailyProgress = "daily_progress"
        case weeklyCheckpoint = "weekly_checkpoint"
        case levelAssessment = "level_assessment"
    }
    
    struct AssessmentQuestion: Codable {
        let id: String
        let type: String
        let question: String
        let options: [String]?
        let correct: String
        let explanation: String?
        let category: String
    }
    
    struct AssessmentPassingCriteria: Codable {
        let overall: Int
        let vocabulary: Int
        let grammar: Int
        let reading: Int
        let writing: Int
    }
    
    struct AssessmentResults: Codable {
        let vocabulary: Double
        let grammar: Double
        let reading: Double
        let writing: Double
        let speaking: Double
        let overall: Double
        let passed: Bool
        let feedback: String
        let recommendations: [String]
    }
    
    struct Assessment: Codable {
        let id: String
        let type: AssessmentType
        let level: String
        let targetLevel: String
        let questions: [AssessmentQuestion]
        let passingCriteria: AssessmentPassingCriteria
        let score: Float
        let passed: Bool
        let results: AssessmentResults?
        let completedAt: Date?
        let createdAt: Date
    }
    
    // MARK: - Progress Models
    
    struct Progress: Codable {
        let id: String
        let currentDay: Int
        let totalDaysCompleted: Int
        let totalLessonsCompleted: Int
        let totalWordsLearned: Int
        let totalStudyTime: Int // in minutes
        let currentStreak: Int
        let longestStreak: Int
        let lastStudyDate: Date?
        let createdAt: Date
        let updatedAt: Date
    }
}

// MARK: - Type Aliases for Convenience

typealias LearningDailyStructure = LearningModels.DailyStructure
typealias LearningWeeklyTheme = LearningModels.WeeklyTheme
typealias LearningAssessmentCheckpoint = LearningModels.LearningAssessmentCheckpoint
typealias LearningAssessmentCriteria = LearningModels.LearningAssessmentCriteria
typealias LearningPlan = LearningModels.LearningPlan
typealias LearningLessonType = LearningModels.LessonType
typealias LearningLessonStatus = LearningModels.LessonStatus
typealias LearningLessonContent = LearningModels.LessonContent
typealias LearningVocabularyItem = LearningModels.VocabularyItem
typealias LearningGrammarContent = LearningModels.GrammarContent
typealias LearningLessonExercise = LearningModels.LessonExercise
typealias LearningLesson = LearningModels.Lesson
typealias LearningAssessmentType = LearningModels.AssessmentType
typealias LearningAssessmentQuestion = LearningModels.AssessmentQuestion
typealias LearningAssessmentPassingCriteria = LearningModels.AssessmentPassingCriteria
typealias LearningAssessmentResults = LearningModels.AssessmentResults
typealias LearningAssessment = LearningModels.Assessment
typealias LearningProgress = LearningModels.Progress
