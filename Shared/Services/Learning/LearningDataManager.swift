//
//  LearningDataManager.swift
//  My Dictionary
//
//  Created by AI Learning Development Team on 3/9/25.
//

import Foundation
import CoreData
import Combine

final class LearningDataManager: ObservableObject {
    
    static let shared = LearningDataManager()
    
    private let coreDataService = CoreDataService.shared
    private var cancellables: Set<AnyCancellable> = []
    
    @Published var currentLearningProfile: CDLearningProfile?
    @Published var currentLearningPlan: CDLearningPlan?
    @Published var todaysLessons: [CDLesson] = []
    @Published var progress: CDProgress?
    
    private init() {
        setupBindings()
        loadCurrentLearningProfile()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        coreDataService.dataUpdatedPublisher
            .sink { [weak self] _ in
                self?.loadCurrentLearningProfile()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Learning Profile Management
    
    /// Load the current learning profile
    private func loadCurrentLearningProfile() {
        let request: NSFetchRequest<CDLearningProfile> = CDLearningProfile.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDLearningProfile.createdAt, ascending: false)]
        
        do {
            let profiles = try coreDataService.context.fetch(request)
            currentLearningProfile = profiles.first
            
            if let profile = currentLearningProfile {
                loadLearningPlan(for: profile)
                loadProgress(for: profile)
                loadTodaysLessons(for: profile)
            }
        } catch {
            print("❌ [LearningDataManager] Error loading learning profile: \(error)")
        }
    }
    
    /// Create a new learning profile
    func createLearningProfile(from profile: LearningProfile) throws -> CDLearningProfile {
        let entity = CDLearningProfile.create(from: profile, in: coreDataService.context)
        try coreDataService.saveContext()
        
        currentLearningProfile = entity
        return entity
    }
    
    /// Update the current learning profile
    func updateLearningProfile(_ profile: LearningProfile) throws {
        guard let entity = currentLearningProfile else {
            throw LearningError.noLearningProfile
        }
        
        entity.update(from: profile)
        try coreDataService.saveContext()
    }
    
    /// Delete the current learning profile
    func deleteLearningProfile() throws {
        guard let entity = currentLearningProfile else {
            throw LearningError.noLearningProfile
        }
        
        coreDataService.context.delete(entity)
        try coreDataService.saveContext()
        
        currentLearningProfile = nil
        currentLearningPlan = nil
        progress = nil
        todaysLessons = []
    }
    
    // MARK: - Learning Plan Management
    
    /// Load learning plan for a profile
    private func loadLearningPlan(for profile: CDLearningProfile) {
        currentLearningPlan = profile.learningPlan
    }
    
    /// Create a new learning plan
    func createLearningPlan(_ plan: LearningModels.LearningPlan, for profile: CDLearningProfile) throws -> CDLearningPlan {
        let entity = CDLearningPlan.create(from: plan, in: coreDataService.context)
        entity.learningProfile = profile
        profile.learningPlan = entity
        
        try coreDataService.saveContext()
        
        currentLearningPlan = entity
        return entity
    }
    
    /// Update the current learning plan
    func updateLearningPlan(_ plan: LearningModels.LearningPlan) throws {
        guard let entity = currentLearningPlan else {
            throw LearningError.noLearningPlan
        }
        
        entity.update(from: plan)
        try coreDataService.saveContext()
    }
    
    // MARK: - Lesson Management
    
    /// Load today's lessons for a profile
    private func loadTodaysLessons(for profile: CDLearningProfile) {
        let request: NSFetchRequest<CDLesson> = CDLesson.fetchRequest()
        request.predicate = NSPredicate(format: "learningProfile == %@", profile)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDLesson.week, ascending: true),
            NSSortDescriptor(keyPath: \CDLesson.day, ascending: true)
        ]
        
        do {
            let lessons = try coreDataService.context.fetch(request)
            todaysLessons = lessons
        } catch {
            print("❌ [LearningDataManager] Error loading lessons: \(error)")
        }
    }
    
    /// Create a new lesson
    func createLesson(_ lesson: LearningModels.Lesson, for profile: CDLearningProfile) throws -> CDLesson {
        let entity = CDLesson.create(from: lesson, in: coreDataService.context)
        entity.learningProfile = profile
        entity.learningPlan = currentLearningPlan
        
        try coreDataService.saveContext()
        
        loadTodaysLessons(for: profile)
        return entity
    }
    
    /// Update a lesson
    func updateLesson(_ lesson: LearningModels.Lesson) throws {
        let request: NSFetchRequest<CDLesson> = CDLesson.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", lesson.id)
        
        do {
            let lessons = try coreDataService.context.fetch(request)
            guard let entity = lessons.first else {
                throw LearningError.lessonNotFound
            }
            
            entity.update(from: lesson)
            try coreDataService.saveContext()
            
            loadTodaysLessons(for: currentLearningProfile!)
        } catch {
            throw error
        }
    }
    
    /// Mark lesson as completed
    func completeLesson(id: String, timeSpent: Int, score: Float) throws {
        let request: NSFetchRequest<CDLesson> = CDLesson.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)

        do {
            let lessons = try coreDataService.context.fetch(request)
            guard let entity = lessons.first else {
                throw LearningError.lessonNotFound
            }
            
            entity.markAsCompleted(timeSpent: timeSpent, score: score)
            try coreDataService.saveContext()
            
            // Update progress
            if let progress = progress {
                progress.updateDailyProgress(lessonsCompleted: 1, wordsLearned: 0, studyTime: timeSpent)
                progress.updateStreak()
                try coreDataService.saveContext()
            }
            
            loadTodaysLessons(for: currentLearningProfile!)
        } catch {
            throw error
        }
    }
    
    // MARK: - Assessment Management
    
    /// Create a new assessment
    func createAssessment(_ assessment: LearningModels.Assessment, for profile: CDLearningProfile) throws -> CDAssessment {
        let entity = CDAssessment.create(from: assessment, in: coreDataService.context)
        entity.learningProfile = profile
        
        try coreDataService.saveContext()
        return entity
    }
    
    /// Complete an assessment
    func completeAssessment(id: String, score: Float, passed: Bool, results: LearningModels.AssessmentResults) throws {
        let request: NSFetchRequest<CDAssessment> = CDAssessment.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)

        do {
            let assessments = try coreDataService.context.fetch(request)
            guard let entity = assessments.first else {
                throw LearningError.assessmentNotFound
            }
            
            entity.markAsCompleted(score: score, passed: passed, results: results)
            try coreDataService.saveContext()
        } catch {
            throw error
        }
    }
    
    // MARK: - Progress Management
    
    /// Load progress for a profile
    private func loadProgress(for profile: CDLearningProfile) {
        progress = profile.progress
    }
    
    /// Create initial progress
    func createInitialProgress(for profile: CDLearningProfile) throws -> CDProgress {
        let initialProgress = LearningModels.Progress(
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
        
        let entity = CDProgress.create(from: initialProgress, in: coreDataService.context)
        entity.learningProfile = profile
        profile.progress = entity
        
        try coreDataService.saveContext()
        
        progress = entity
        return entity
    }
    
    /// Update progress
    func updateProgress(_ progress: LearningModels.Progress) throws {
        guard let entity = self.progress else {
            throw LearningError.noProgress
        }
        
        entity.update(from: progress)
        try coreDataService.saveContext()
    }
    
    // MARK: - Sync Management
    
    /// Get all entities that need sync
    func getEntitiesNeedingSync() -> [NSManagedObject] {
        var entities: [NSManagedObject] = []
        
        if let profile = currentLearningProfile, profile.needsSync {
            entities.append(profile)
        }
        
        if let plan = currentLearningPlan, plan.needsSync {
            entities.append(plan)
        }
        
        if let progress = progress, progress.needsSync {
            entities.append(progress)
        }
        
        // Add lessons that need sync
        let lessonRequest: NSFetchRequest<CDLesson> = CDLesson.fetchRequest()
        lessonRequest.predicate = NSPredicate(format: "syncedAt == nil")
        
        do {
            let lessons = try coreDataService.context.fetch(lessonRequest)
            entities.append(contentsOf: lessons)
        } catch {
            print("❌ [LearningDataManager] Error fetching lessons needing sync: \(error)")
        }
        
        // Add assessments that need sync
        let assessmentRequest: NSFetchRequest<CDAssessment> = CDAssessment.fetchRequest()
        assessmentRequest.predicate = NSPredicate(format: "syncedAt == nil")
        
        do {
            let assessments = try coreDataService.context.fetch(assessmentRequest)
            entities.append(contentsOf: assessments)
        } catch {
            print("❌ [LearningDataManager] Error fetching assessments needing sync: \(error)")
        }
        
        return entities
    }
    
    /// Mark entity as synced
    func markAsSynced(_ entity: NSManagedObject) throws {
        if let profile = entity as? CDLearningProfile {
            profile.markAsSynced()
        } else if let plan = entity as? CDLearningPlan {
            plan.markAsSynced()
        } else if let lesson = entity as? CDLesson {
            lesson.markAsSynced()
        } else if let assessment = entity as? CDAssessment {
            assessment.markAsSynced()
        } else if let progress = entity as? CDProgress {
            progress.markAsSynced()
        }
        
        try coreDataService.saveContext()
    }
}

// MARK: - Errors

enum LearningError: Error, LocalizedError {
    case noLearningProfile
    case noLearningPlan
    case noProgress
    case lessonNotFound
    case assessmentNotFound
    
    var errorDescription: String? {
        switch self {
        case .noLearningProfile:
            return "No learning profile found"
        case .noLearningPlan:
            return "No learning plan found"
        case .noProgress:
            return "No progress found"
        case .lessonNotFound:
            return "Lesson not found"
        case .assessmentNotFound:
            return "Assessment not found"
        }
    }
}
