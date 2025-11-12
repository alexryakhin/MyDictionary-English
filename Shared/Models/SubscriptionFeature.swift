//
//  SubscriptionFeature 2.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/23/25.
//

import OpenAI

enum SubscriptionFeature: String, Codable, CaseIterable, JSONSchemaEnumConvertible {
    case aiDefinitions = "ai_definitions"
    case aiQuizzes = "ai_quizzes"
    case aiLessons = "ai_lessons"
    case images = "images"
    case wordCollections = "word_collections"
    case premiumTTS = "premium_tts"
    case unlimitedExport = "unlimited_export"
    case createSharedDictionaries = "create_shared_dictionaries"
    case tagManagement = "tag_management"
    case advancedAnalytics = "advanced_analytics"
    case prioritySupport = "priority_support"

    var displayName: String {
        switch self {
        case .aiDefinitions: Loc.Subscription.ProFeatures.aiDefinitions
        case .aiQuizzes: Loc.Subscription.ProFeatures.aiQuizzes
        case .aiLessons: Loc.Subscription.ProFeatures.aiLessons
        case .premiumTTS: Loc.Subscription.ProFeatures.speechifyTts
        case .unlimitedExport: Loc.Subscription.ProFeatures.unlimitedExport
        case .createSharedDictionaries: Loc.Subscription.ProFeatures.createSharedDictionaries
        case .tagManagement: Loc.Subscription.ProFeatures.tagManagement
        case .advancedAnalytics: Loc.Subscription.ProFeatures.advancedAnalytics
        case .prioritySupport: Loc.Subscription.ProFeatures.prioritySupport
        case .images: Loc.Subscription.ProFeatures.images
        case .wordCollections: Loc.Subscription.ProFeatures.wordCollections
        }
    }

    var description: String {
        switch self {
        case .aiDefinitions: Loc.Subscription.ProFeatures.aiDefinitionsDescription
        case .aiQuizzes: Loc.Subscription.ProFeatures.aiQuizzesDescription
        case .aiLessons: Loc.Subscription.ProFeatures.aiLessonsDescription
        case .premiumTTS: Loc.Subscription.ProFeatures.speechifyTtsDescription
        case .unlimitedExport: Loc.Subscription.ProFeatures.syncWordsAcrossDevices
        case .createSharedDictionaries: Loc.Subscription.ProFeatures.createManageSharedDictionaries
        case .tagManagement: Loc.Subscription.ProFeatures.organizeWordsWithTags
        case .advancedAnalytics: Loc.Subscription.ProFeatures.detailedInsights
        case .prioritySupport: Loc.Subscription.ProFeatures.prioritySupportTeam
        case .images: Loc.Subscription.ProFeatures.imagesDescription
        case .wordCollections: Loc.Subscription.ProFeatures.wordCollectionsDescription
        }
    }

    var iconName: String {
        switch self {
        case .aiDefinitions: "character.magnify"
        case .aiQuizzes: "brain.head.profile"
        case .aiLessons: "graduationcap.fill"
        case .premiumTTS: "person.wave.2.fill"
        case .unlimitedExport: "square.and.arrow.up"
        case .createSharedDictionaries: "person.2.fill"
        case .tagManagement: "tag.fill"
        case .advancedAnalytics: "chart.bar.fill"
        case .prioritySupport: "star.fill"
        case .images: "photo.fill"
        case .wordCollections: "folder.fill"
        }
    }
    
    // MARK: - JSONSchemaEnumConvertible

    var caseNames: [String] {
        return Self.allCases.map { $0.rawValue }
    }
}
