//
//  LearningOnboarding.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

// MARK: - Learning Onboarding Screen

enum LearningOnboardingScreen: CaseIterable {
    case welcome
    case targetLanguage
    case currentLevel
    case interests
    case learningGoals
    case timeCommitment
    case learningStyle
    case nativeLanguage
    case motivation
    case summary
    
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
    
    var isLastScreen: Bool {
        self == .summary
    }
}

// MARK: - Learning Profile Models

struct LearningProfile: Codable {
    let id: String
    let targetLanguage: InputLanguage
    let currentLevel: LanguageLevel
    let interests: [LearningInterest]
    let learningGoals: [LearningGoal]
    let timeCommitment: TimeCommitment
    let learningStyle: LearningStyle
    let nativeLanguage: InputLanguage
    let motivation: LearningMotivation
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        targetLanguage: InputLanguage = .english,
        currentLevel: LanguageLevel = .beginner,
        interests: [LearningInterest] = [],
        learningGoals: [LearningGoal] = [],
        timeCommitment: TimeCommitment = .casual,
        learningStyle: LearningStyle = .balanced,
        nativeLanguage: InputLanguage = .english,
        motivation: LearningMotivation = .personal,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.targetLanguage = targetLanguage
        self.currentLevel = currentLevel
        self.interests = interests
        self.learningGoals = learningGoals
        self.timeCommitment = timeCommitment
        self.learningStyle = learningStyle
        self.nativeLanguage = nativeLanguage
        self.motivation = motivation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Language Level

enum LanguageLevel: String, Codable, CaseIterable, Identifiable {
    case beginner = "beginner"
    case elementary = "elementary"
    case intermediate = "intermediate"
    case upperIntermediate = "upper_intermediate"
    case advanced = "advanced"
    case native = "native"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .beginner: return Loc.Learning.LanguageLevel.beginner
        case .elementary: return Loc.Learning.LanguageLevel.elementary
        case .intermediate: return Loc.Learning.LanguageLevel.intermediate
        case .upperIntermediate: return Loc.Learning.LanguageLevel.upperIntermediate
        case .advanced: return Loc.Learning.LanguageLevel.advanced
        case .native: return Loc.Learning.LanguageLevel.native
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return Loc.Learning.LanguageLevel.beginnerDescription
        case .elementary: return Loc.Learning.LanguageLevel.elementaryDescription
        case .intermediate: return Loc.Learning.LanguageLevel.intermediateDescription
        case .upperIntermediate: return Loc.Learning.LanguageLevel.upperIntermediateDescription
        case .advanced: return Loc.Learning.LanguageLevel.advancedDescription
        case .native: return Loc.Learning.LanguageLevel.nativeDescription
        }
    }
    
    var iconName: String {
        switch self {
        case .beginner: return "1.circle.fill"
        case .elementary: return "2.circle.fill"
        case .intermediate: return "3.circle.fill"
        case .upperIntermediate: return "4.circle.fill"
        case .advanced: return "5.circle.fill"
        case .native: return "star.fill"
        }
    }
}

// MARK: - Learning Interest

struct LearningInterest: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let iconName: String
    let category: InterestCategory
    
    init(id: String = UUID().uuidString, title: String, iconName: String, category: InterestCategory) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.category = category
    }
}

enum InterestCategory: String, Codable, CaseIterable {
    case lifestyle = "lifestyle"
    case technology = "technology"
    case entertainment = "entertainment"
    case education = "education"
    case business = "business"
    case travel = "travel"
    case culture = "culture"
    case health = "health"
    case sports = "sports"
    case food = "food"
    
    var displayName: String {
        switch self {
        case .lifestyle: return Loc.Learning.InterestCategory.lifestyle
        case .technology: return Loc.Learning.InterestCategory.technology
        case .entertainment: return Loc.Learning.InterestCategory.entertainment
        case .education: return Loc.Learning.InterestCategory.education
        case .business: return Loc.Learning.InterestCategory.business
        case .travel: return Loc.Learning.InterestCategory.travel
        case .culture: return Loc.Learning.InterestCategory.culture
        case .health: return Loc.Learning.InterestCategory.health
        case .sports: return Loc.Learning.InterestCategory.sports
        case .food: return Loc.Learning.InterestCategory.food
        }
    }
}

// MARK: - Learning Goal

enum LearningGoal: String, Codable, CaseIterable, Identifiable {
    case travel = "travel"
    case work = "work"
    case study = "study"
    case personal = "personal"
    case family = "family"
    case exam = "exam"
    case business = "business"
    case culture = "culture"
    case hobby = "hobby"
    case migration = "migration"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .travel: return Loc.Learning.LearningGoals.travel
        case .work: return Loc.Learning.LearningGoals.work
        case .study: return Loc.Learning.LearningGoals.study
        case .personal: return Loc.Learning.LearningGoals.personal
        case .family: return Loc.Learning.LearningGoals.family
        case .exam: return Loc.Learning.LearningGoals.exam
        case .business: return Loc.Learning.LearningGoals.business
        case .culture: return Loc.Learning.LearningGoals.culture
        case .hobby: return Loc.Learning.LearningGoals.hobby
        case .migration: return Loc.Learning.LearningGoals.migration
        }
    }
    
    var description: String {
        switch self {
        case .travel: return Loc.Learning.LearningGoals.travelDescription
        case .work: return Loc.Learning.LearningGoals.workDescription
        case .study: return Loc.Learning.LearningGoals.studyDescription
        case .personal: return Loc.Learning.LearningGoals.personalDescription
        case .family: return Loc.Learning.LearningGoals.familyDescription
        case .exam: return Loc.Learning.LearningGoals.examDescription
        case .business: return Loc.Learning.LearningGoals.businessDescription
        case .culture: return Loc.Learning.LearningGoals.cultureDescription
        case .hobby: return Loc.Learning.LearningGoals.hobbyDescription
        case .migration: return Loc.Learning.LearningGoals.migrationDescription
        }
    }
    
    var iconName: String {
        switch self {
        case .travel: return "airplane"
        case .work: return "briefcase.fill"
        case .study: return "graduationcap.fill"
        case .personal: return "person.fill"
        case .family: return "person.2.fill"
        case .exam: return "doc.text.fill"
        case .business: return "building.2.fill"
        case .culture: return "theatermasks.fill"
        case .hobby: return "paintbrush.fill"
        case .migration: return "house.fill"
        }
    }
}

// MARK: - Time Commitment

enum TimeCommitment: String, Codable, CaseIterable, Identifiable {
    case casual = "casual"
    case regular = "regular"
    case intensive = "intensive"
    case intensivePlus = "intensive_plus"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .casual: return Loc.Learning.TimeCommitment.casual
        case .regular: return Loc.Learning.TimeCommitment.regular
        case .intensive: return Loc.Learning.TimeCommitment.intensive
        case .intensivePlus: return Loc.Learning.TimeCommitment.intensivePlus
        }
    }
    
    var description: String {
        switch self {
        case .casual: return Loc.Learning.TimeCommitment.casualDescription
        case .regular: return Loc.Learning.TimeCommitment.regularDescription
        case .intensive: return Loc.Learning.TimeCommitment.intensiveDescription
        case .intensivePlus: return Loc.Learning.TimeCommitment.intensivePlusDescription
        }
    }
    
    var minutesPerDay: Int {
        switch self {
        case .casual: return 10
        case .regular: return 20
        case .intensive: return 45
        case .intensivePlus: return 90
        }
    }
    
    var iconName: String {
        switch self {
        case .casual: return "clock.fill"
        case .regular: return "clock.circle.fill"
        case .intensive: return "timer"
        case .intensivePlus: return "stopwatch.fill"
        }
    }
}

// MARK: - Learning Style

enum LearningStyle: String, Codable, CaseIterable, Identifiable {
    case visual = "visual"
    case auditory = "auditory"
    case kinesthetic = "kinesthetic"
    case reading = "reading"
    case balanced = "balanced"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .visual: return Loc.Learning.LearningStyle.visual
        case .auditory: return Loc.Learning.LearningStyle.auditory
        case .kinesthetic: return Loc.Learning.LearningStyle.kinesthetic
        case .reading: return Loc.Learning.LearningStyle.reading
        case .balanced: return Loc.Learning.LearningStyle.balanced
        }
    }
    
    var description: String {
        switch self {
        case .visual: return Loc.Learning.LearningStyle.visualDescription
        case .auditory: return Loc.Learning.LearningStyle.auditoryDescription
        case .kinesthetic: return Loc.Learning.LearningStyle.kinestheticDescription
        case .reading: return Loc.Learning.LearningStyle.readingDescription
        case .balanced: return Loc.Learning.LearningStyle.balancedDescription
        }
    }
    
    var iconName: String {
        switch self {
        case .visual: return "eye.fill"
        case .auditory: return "ear.fill"
        case .kinesthetic: return "hand.point.up.fill"
        case .reading: return "book.fill"
        case .balanced: return "circle.grid.3x3.fill"
        }
    }
}

// MARK: - Learning Motivation

enum LearningMotivation: String, Codable, CaseIterable, Identifiable {
    case personal = "personal"
    case professional = "professional"
    case academic = "academic"
    case social = "social"
    case cultural = "cultural"
    case challenge = "challenge"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .personal: return Loc.Learning.Motivation.personal
        case .professional: return Loc.Learning.Motivation.professional
        case .academic: return Loc.Learning.Motivation.academic
        case .social: return Loc.Learning.Motivation.social
        case .cultural: return Loc.Learning.Motivation.cultural
        case .challenge: return Loc.Learning.Motivation.challenge
        }
    }
    
    var description: String {
        switch self {
        case .personal: return Loc.Learning.Motivation.personalDescription
        case .professional: return Loc.Learning.Motivation.professionalDescription
        case .academic: return Loc.Learning.Motivation.academicDescription
        case .social: return Loc.Learning.Motivation.socialDescription
        case .cultural: return Loc.Learning.Motivation.culturalDescription
        case .challenge: return Loc.Learning.Motivation.challengeDescription
        }
    }
    
    var iconName: String {
        switch self {
        case .personal: return "heart.fill"
        case .professional: return "briefcase.fill"
        case .academic: return "graduationcap.fill"
        case .social: return "person.2.fill"
        case .cultural: return "theatermasks.fill"
        case .challenge: return "trophy.fill"
        }
    }
}

// MARK: - Predefined Learning Interests

extension LearningInterest {
    static let allInterests: [LearningInterest] = [
        // Lifestyle
        LearningInterest(title: Loc.Learning.Interests.lifestyle, iconName: "house.fill", category: .lifestyle),
        LearningInterest(title: Loc.Learning.Interests.fashion, iconName: "tshirt.fill", category: .lifestyle),
        LearningInterest(title: Loc.Learning.Interests.beauty, iconName: "sparkles", category: .lifestyle),
        LearningInterest(title: Loc.Learning.Interests.home, iconName: "house.circle.fill", category: .lifestyle),
        
        // Technology
        LearningInterest(title: Loc.Learning.Interests.technology, iconName: "laptopcomputer", category: .technology),
        LearningInterest(title: Loc.Learning.Interests.gaming, iconName: "gamecontroller.fill", category: .technology),
        LearningInterest(title: Loc.Learning.Interests.programming, iconName: "terminal.fill", category: .technology),
        LearningInterest(title: Loc.Learning.Interests.socialMedia, iconName: "message.fill", category: .technology),
        
        // Entertainment
        LearningInterest(title: Loc.Learning.Interests.movies, iconName: "tv.fill", category: .entertainment),
        LearningInterest(title: Loc.Learning.Interests.music, iconName: "music.note", category: .entertainment),
        LearningInterest(title: Loc.Learning.Interests.books, iconName: "book.fill", category: .entertainment),
        LearningInterest(title: Loc.Learning.Interests.art, iconName: "paintbrush.fill", category: .entertainment),
        
        // Education
        LearningInterest(title: Loc.Learning.Interests.science, iconName: "atom", category: .education),
        LearningInterest(title: Loc.Learning.Interests.history, iconName: "scroll.fill", category: .education),
        LearningInterest(title: Loc.Learning.Interests.literature, iconName: "book.closed.fill", category: .education),
        LearningInterest(title: Loc.Learning.Interests.philosophy, iconName: "brain.head.profile", category: .education),
        
        // Business
        LearningInterest(title: Loc.Learning.Interests.business, iconName: "building.2.fill", category: .business),
        LearningInterest(title: Loc.Learning.Interests.finance, iconName: "dollarsign.circle.fill", category: .business),
        LearningInterest(title: Loc.Learning.Interests.marketing, iconName: "megaphone.fill", category: .business),
        LearningInterest(title: Loc.Learning.Interests.entrepreneurship, iconName: "lightbulb.fill", category: .business),
        
        // Travel
        LearningInterest(title: Loc.Learning.Interests.travel, iconName: "airplane", category: .travel),
        LearningInterest(title: Loc.Learning.Interests.adventure, iconName: "mountain.2.fill", category: .travel),
        LearningInterest(title: Loc.Learning.Interests.culture, iconName: "theatermasks.fill", category: .travel),
        LearningInterest(title: Loc.Learning.Interests.photography, iconName: "camera.fill", category: .travel),
        
        // Health
        LearningInterest(title: Loc.Learning.Interests.fitness, iconName: "figure.run", category: .health),
        LearningInterest(title: Loc.Learning.Interests.nutrition, iconName: "leaf.fill", category: .health),
        LearningInterest(title: Loc.Learning.Interests.mentalHealth, iconName: "brain.head.profile", category: .health),
        LearningInterest(title: Loc.Learning.Interests.medicine, iconName: "cross.fill", category: .health),
        
        // Sports
        LearningInterest(title: Loc.Learning.Interests.soccer, iconName: "soccerball", category: .sports),
        LearningInterest(title: Loc.Learning.Interests.basketball, iconName: "basketball.fill", category: .sports),
        LearningInterest(title: Loc.Learning.Interests.tennis, iconName: "tennisball.fill", category: .sports),
        LearningInterest(title: Loc.Learning.Interests.swimming, iconName: "figure.pool.swim", category: .sports),
        
        // Food
        LearningInterest(title: Loc.Learning.Interests.cooking, iconName: "fork.knife", category: .food),
        LearningInterest(title: Loc.Learning.Interests.baking, iconName: "birthday.cake.fill", category: .food),
        LearningInterest(title: Loc.Learning.Interests.coffee, iconName: "cup.and.saucer.fill", category: .food),
        LearningInterest(title: Loc.Learning.Interests.wine, iconName: "wineglass.fill", category: .food)
    ]
}
