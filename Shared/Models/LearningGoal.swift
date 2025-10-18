//
//  LearningGoal.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/18/25.
//

import Foundation

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
