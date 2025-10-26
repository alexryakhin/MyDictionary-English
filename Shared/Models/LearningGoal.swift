//
//  LearningGoal.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/18/25.
//

import Foundation

enum LearningGoal: String, Codable, CaseIterable, Identifiable {
    case career = "career"
    case travel = "travel"
    case education = "education"
    case personalGrowth = "personal_growth"
    case immigration = "immigration"
    case family = "family"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .career: return Loc.Onboarding.LearningGoal.career
        case .travel: return Loc.Onboarding.LearningGoal.travel
        case .education: return Loc.Onboarding.LearningGoal.education
        case .personalGrowth: return Loc.Onboarding.LearningGoal.personalGrowth
        case .immigration: return Loc.Onboarding.LearningGoal.immigration
        case .family: return Loc.Onboarding.LearningGoal.family
        }
    }

    var iconName: String {
        switch self {
        case .career: return "briefcase.fill"
        case .travel: return "airplane"
        case .education: return "graduationcap.fill"
        case .personalGrowth: return "person.fill"
        case .immigration: return "house.fill"
        case .family: return "person.2.fill"
        }
    }
}
