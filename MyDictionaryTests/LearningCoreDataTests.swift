//
//  LearningCoreDataTests.swift
//  My Dictionary
//
//  Created by AI Learning Development Team on 3/9/25.
//

import XCTest
import CoreData
import My_Dictionary

final class LearningCoreDataTests: XCTestCase {
    
    var context: NSManagedObjectContext!
    var dataManager: LearningDataManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory Core Data stack for testing
        let container = NSPersistentContainer(name: "My_Dictionary")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
        
        context = container.viewContext
        dataManager = LearningDataManager.shared
    }
    
    override func tearDownWithError() throws {
        context = nil
        dataManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - LearningProfile Tests
    
    func testCreateLearningProfile() throws {
        // Given
        let profile = LearningProfile(
            targetLanguage: .spanish,
            currentLevel: .beginner,
            interests: [LearningInterest(title: "Travel", iconName: "airplane", category: .travel)],
            learningGoals: [.travel, .personal],
            timeCommitment: .regular,
            learningStyle: .visual,
            nativeLanguage: .english,
            motivation: .personal
        )
        
        // When
        let entity = CDLearningProfile.create(from: profile, in: context)
        
        // Then
        XCTAssertNotNil(entity.id)
        XCTAssertEqual(entity.targetLanguage, "spanish")
        XCTAssertEqual(entity.currentLevel, "beginner")
        XCTAssertEqual(entity.timeCommitment, "regular")
        XCTAssertEqual(entity.learningStyle, "visual")
        XCTAssertEqual(entity.nativeLanguage, "english")
        XCTAssertEqual(entity.motivation, "personal")
        XCTAssertNotNil(entity.createdAt)
        XCTAssertNotNil(entity.updatedAt)
        XCTAssertNil(entity.syncedAt)
        XCTAssertTrue(entity.needsSync)
    }
    
    func testLearningProfileToModel() throws {
        // Given
        let profile = LearningProfile(
            targetLanguage: .french,
            currentLevel: .intermediate,
            interests: [LearningInterest(title: "Cooking", iconName: "fork.knife", category: .food)],
            learningGoals: [.work, .study],
            timeCommitment: .intensive,
            learningStyle: .auditory,
            nativeLanguage: .english,
            motivation: .professional
        )
        
        // When
        let entity = CDLearningProfile.create(from: profile, in: context)
        let convertedProfile = entity.toLearningProfile
        
        // Then
        XCTAssertEqual(convertedProfile.targetLanguage, .french)
        XCTAssertEqual(convertedProfile.currentLevel, .intermediate)
        XCTAssertEqual(convertedProfile.timeCommitment, .intensive)
        XCTAssertEqual(convertedProfile.learningStyle, .auditory)
        XCTAssertEqual(convertedProfile.nativeLanguage, .english)
        XCTAssertEqual(convertedProfile.motivation, .professional)
        XCTAssertEqual(convertedProfile.interests.count, 1)
        XCTAssertEqual(convertedProfile.learningGoals.count, 2)
    }
    
    func testUpdateLearningProfile() throws {
        // Given
        let originalProfile = LearningProfile(
            targetLanguage: .spanish,
            currentLevel: .beginner,
            interests: [],
            learningGoals: [.personal],
            timeCommitment: .casual,
            learningStyle: .balanced,
            nativeLanguage: .english,
            motivation: .personal
        )
        
        let entity = CDLearningProfile.create(from: originalProfile, in: context)
        
        // When
        let updatedProfile = LearningProfile(
            id: originalProfile.id,
            targetLanguage: .spanish,
            currentLevel: .elementary, // Changed
            interests: [LearningInterest(title: "Music", iconName: "music.note", category: .entertainment)],
            learningGoals: [.travel, .work], // Changed
            timeCommitment: .regular, // Changed
            learningStyle: .visual, // Changed
            nativeLanguage: .english,
            motivation: .professional, // Changed
            createdAt: originalProfile.createdAt,
            updatedAt: Date()
        )
        
        entity.update(from: updatedProfile)
        
        // Then
        XCTAssertEqual(entity.currentLevel, "elementary")
        XCTAssertEqual(entity.timeCommitment, "regular")
        XCTAssertEqual(entity.learningStyle, "visual")
        XCTAssertEqual(entity.motivation, "professional")
        XCTAssertNotNil(entity.updatedAt)
        XCTAssertNil(entity.syncedAt)
        XCTAssertTrue(entity.needsSync)
    }
    
    // MARK: - LearningPlan Tests
    
    func testCreateLearningPlan() throws {
        // Given
        let dailyStructure = LearningModels.DailyStructure(vocabulary: 15, grammar: 10, speaking: 10, writing: 5, reading: 10)
        let weeklyTheme = LearningModels.WeeklyTheme(week: 1, theme: "daily_routines", vocabulary: 50, grammar: ["present_tense"], assessments: ["vocabulary_quiz"])
        let checkpoint = LearningModels.LearningAssessmentCheckpoint(day: 7, type: "level_assessment", criteria: LearningModels.LearningAssessmentCriteria(vocabulary: 80, grammar: 75, speaking: 70, writing: 65))
        
        let plan = LearningModels.LearningPlan(
            id: UUID().uuidString,
            targetLanguage: "spanish",
            currentLevel: "beginner",
            totalDuration: 30,
            dailyStructure: dailyStructure,
            weeklyThemes: [weeklyTheme],
            assessmentCheckpoints: [checkpoint],
            createdAt: Date()
        )
        
        // When
        let entity = CDLearningPlan.create(from: plan, in: context)
        
        // Then
        XCTAssertNotNil(entity.id)
        XCTAssertEqual(entity.targetLanguage, "spanish")
        XCTAssertEqual(entity.currentLevel, "beginner")
        XCTAssertEqual(entity.totalDuration, 30)
        XCTAssertNotNil(entity.dailyStructure)
        XCTAssertNotNil(entity.weeklyThemes)
        XCTAssertNotNil(entity.assessmentCheckpoints)
        XCTAssertNotNil(entity.createdAt)
        XCTAssertTrue(entity.needsSync)
    }
    
    func testLearningPlanToModel() throws {
        // Given
        let dailyStructure = LearningModels.DailyStructure(vocabulary: 20, grammar: 15, speaking: 15, writing: 10, reading: 15)
        let plan = LearningModels.LearningPlan(
            id: UUID().uuidString,
            targetLanguage: "french",
            currentLevel: "intermediate",
            totalDuration: 60,
            dailyStructure: dailyStructure,
            weeklyThemes: [],
            assessmentCheckpoints: [],
            createdAt: Date()
        )
        
        // When
        let entity = CDLearningPlan.create(from: plan, in: context)
        let convertedPlan = entity.toLearningPlan
        
        // Then
        XCTAssertEqual(convertedPlan.targetLanguage, "french")
        XCTAssertEqual(convertedPlan.currentLevel, "intermediate")
        XCTAssertEqual(convertedPlan.totalDuration, 60)
        XCTAssertEqual(convertedPlan.dailyStructure.vocabulary, 20)
        XCTAssertEqual(convertedPlan.dailyStructure.grammar, 15)
    }
    
    // MARK: - Lesson Tests
    
    func testCreateLesson() throws {
        // Given
        let vocabulary = [LearningModels.VocabularyItem(word: "hola", translation: "hello", pronunciation: "/ˈola/", example: "Hola, ¿cómo estás?", memoryTip: "Think of 'hello' but with an 'h'")]
        let content = LearningModels.LessonContent(
            objectives: ["Learn basic greetings", "Practice pronunciation"],
            vocabulary: vocabulary,
            grammar: nil,
            exercises: [],
            examples: ["Hola, ¿cómo estás?", "Buenos días"],
            culturalNotes: ["In Spain, people often kiss on both cheeks when greeting"]
        )
        
        let lesson = LearningModels.Lesson(
            id: UUID().uuidString,
            learningPlanId: "plan-123",
            type: .vocabulary,
            day: 1,
            week: 1,
            theme: "greetings",
            title: "Basic Greetings",
            content: content,
            estimatedDuration: 15,
            difficulty: "beginner",
            status: .notStarted,
            completedAt: nil,
            timeSpent: 0,
            score: 0.0,
            createdAt: Date()
        )
        
        // When
        let entity = CDLesson.create(from: lesson, in: context)
        
        // Then
        XCTAssertNotNil(entity.id)
        XCTAssertEqual(entity.learningPlanId, "plan-123")
        XCTAssertEqual(entity.type, "vocabulary")
        XCTAssertEqual(entity.day, 1)
        XCTAssertEqual(entity.week, 1)
        XCTAssertEqual(entity.theme, "greetings")
        XCTAssertEqual(entity.title, "Basic Greetings")
        XCTAssertEqual(entity.estimatedDuration, 15)
        XCTAssertEqual(entity.difficulty, "beginner")
        XCTAssertEqual(entity.status, "not_started")
        XCTAssertEqual(entity.timeSpent, 0)
        XCTAssertEqual(entity.score, 0.0)
        XCTAssertTrue(entity.needsSync)
    }
    
    func testCompleteLesson() throws {
        // Given
        let content = LearningModels.LessonContent(objectives: [], vocabulary: nil, grammar: nil, exercises: [], examples: [], culturalNotes: nil)
        let lesson = LearningModels.Lesson(
            id: UUID().uuidString,
            learningPlanId: "plan-123",
            type: .grammar,
            day: 2,
            week: 1,
            theme: "present_tense",
            title: "Present Tense",
            content: content,
            estimatedDuration: 20,
            difficulty: "beginner",
            status: .inProgress,
            completedAt: nil,
            timeSpent: 10,
            score: 0.0,
            createdAt: Date()
        )
        
        let entity = CDLesson.create(from: lesson, in: context)
        
        // When
        entity.markAsCompleted(timeSpent: 18, score: 85.0)
        
        // Then
        XCTAssertEqual(entity.status, "completed")
        XCTAssertEqual(entity.timeSpent, 18)
        XCTAssertEqual(entity.score, 85.0)
        XCTAssertNotNil(entity.completedAt)
        XCTAssertNil(entity.syncedAt)
        XCTAssertTrue(entity.needsSync)
    }
    
    // MARK: - Assessment Tests
    
    func testCreateAssessment() throws {
        // Given
        let question = LearningModels.AssessmentQuestion(
            id: "q1",
            type: "multiple_choice",
            question: "What does 'hola' mean?",
            options: ["Hello", "Goodbye", "Thank you", "Please"],
            correct: "Hello",
            explanation: "Hola is the Spanish word for hello",
            category: "vocabulary"
        )
        
        let criteria = LearningModels.AssessmentPassingCriteria(overall: 80, vocabulary: 70, grammar: 70, reading: 70, writing: 70)
        
        let assessment = LearningModels.Assessment(
            id: UUID().uuidString,
            type: .dailyProgress,
            level: "beginner",
            targetLevel: "elementary",
            questions: [question],
            passingCriteria: criteria,
            score: 0.0,
            passed: false,
            results: nil,
            completedAt: nil,
            createdAt: Date()
        )
        
        // When
        let entity = CDAssessment.create(from: assessment, in: context)
        
        // Then
        XCTAssertNotNil(entity.id)
        XCTAssertEqual(entity.type, "daily_progress")
        XCTAssertEqual(entity.level, "beginner")
        XCTAssertEqual(entity.targetLevel, "elementary")
        XCTAssertNotNil(entity.questions)
        XCTAssertNotNil(entity.passingCriteria)
        XCTAssertEqual(entity.score, 0.0)
        XCTAssertFalse(entity.passed)
        XCTAssertNil(entity.results)
        XCTAssertNil(entity.completedAt)
        XCTAssertTrue(entity.needsSync)
    }
    
    func testCompleteAssessment() throws {
        // Given
        let criteria = LearningModels.AssessmentPassingCriteria(overall: 80, vocabulary: 70, grammar: 70, reading: 70, writing: 70)
        let assessment = LearningModels.Assessment(
            id: UUID().uuidString,
            type: .levelAssessment,
            level: "beginner",
            targetLevel: "elementary",
            questions: [],
            passingCriteria: criteria,
            score: 0.0,
            passed: false,
            results: nil,
            completedAt: nil,
            createdAt: Date()
        )
        
        let entity = CDAssessment.create(from: assessment, in: context)
        
        // When
        let results = LearningModels.AssessmentResults(
            vocabulary: 85.0,
            grammar: 80.0,
            reading: 75.0,
            writing: 70.0,
            speaking: 80.0,
            overall: 78.0,
            passed: false,
            feedback: "Good progress, focus on writing skills",
            recommendations: ["Practice writing exercises", "Review grammar rules"]
        )
        
        entity.markAsCompleted(score: 78.0, passed: false, results: results)
        
        // Then
        XCTAssertEqual(entity.score, 78.0)
        XCTAssertFalse(entity.passed)
        XCTAssertNotNil(entity.results)
        XCTAssertNotNil(entity.completedAt)
        XCTAssertNil(entity.syncedAt)
        XCTAssertTrue(entity.needsSync)
    }
    
    // MARK: - Progress Tests
    
    func testCreateProgress() throws {
        // Given
        let progress = LearningModels.Progress(
            id: UUID().uuidString,
            currentDay: 1,
            totalDaysCompleted: 0,
            totalLessonsCompleted: 0,
            totalWordsLearned: 0,
            totalStudyTime: 0,
            currentStreak: 0,
            longestStreak: 0,
            lastStudyDate: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When
        let entity = CDProgress.create(from: progress, in: context)
        
        // Then
        XCTAssertNotNil(entity.id)
        XCTAssertEqual(entity.currentDay, 1)
        XCTAssertEqual(entity.totalDaysCompleted, 0)
        XCTAssertEqual(entity.totalLessonsCompleted, 0)
        XCTAssertEqual(entity.totalWordsLearned, 0)
        XCTAssertEqual(entity.totalStudyTime, 0)
        XCTAssertEqual(entity.currentStreak, 0)
        XCTAssertEqual(entity.longestStreak, 0)
        XCTAssertNil(entity.lastStudyDate)
        XCTAssertTrue(entity.needsSync)
    }
    
    func testUpdateDailyProgress() throws {
        // Given
        let progress = LearningModels.Progress(
            id: UUID().uuidString,
            currentDay: 1,
            totalDaysCompleted: 0,
            totalLessonsCompleted: 0,
            totalWordsLearned: 0,
            totalStudyTime: 0,
            currentStreak: 0,
            longestStreak: 0,
            lastStudyDate: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let entity = CDProgress.create(from: progress, in: context)
        
        // When
        entity.updateDailyProgress(lessonsCompleted: 3, wordsLearned: 15, studyTime: 45)
        
        // Then
        XCTAssertEqual(entity.totalLessonsCompleted, 3)
        XCTAssertEqual(entity.totalWordsLearned, 15)
        XCTAssertEqual(entity.totalStudyTime, 45)
        XCTAssertNotNil(entity.lastStudyDate)
        XCTAssertNotNil(entity.updatedAt)
        XCTAssertTrue(entity.needsSync)
    }
    
    func testUpdateStreak() throws {
        // Given
        let progress = LearningModels.Progress(
            id: UUID().uuidString,
            currentDay: 1,
            totalDaysCompleted: 0,
            totalLessonsCompleted: 0,
            totalWordsLearned: 0,
            totalStudyTime: 0,
            currentStreak: 0,
            longestStreak: 0,
            lastStudyDate: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let entity = CDProgress.create(from: progress, in: context)
        
        // When - First study day
        entity.updateStreak()
        
        // Then
        XCTAssertEqual(entity.currentStreak, 1)
        XCTAssertEqual(entity.longestStreak, 1)
        
        // When - Simulate consecutive days
        entity.updateStreak()
        
        // Then
        XCTAssertEqual(entity.currentStreak, 2)
        XCTAssertEqual(entity.longestStreak, 2)
    }
    
    // MARK: - Sync Tests
    
    func testMarkAsSynced() throws {
        // Given
        let profile = LearningProfile(
            targetLanguage: .spanish,
            currentLevel: .beginner,
            interests: [],
            learningGoals: [.personal],
            timeCommitment: .casual,
            learningStyle: .balanced,
            nativeLanguage: .english,
            motivation: .personal
        )
        
        let entity = CDLearningProfile.create(from: profile, in: context)
        XCTAssertTrue(entity.needsSync)
        
        // When
        entity.markAsSynced()
        
        // Then
        XCTAssertFalse(entity.needsSync)
        XCTAssertNotNil(entity.syncedAt)
    }
}
