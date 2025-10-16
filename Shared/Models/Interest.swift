//
//  Interest.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum Interest: String, Codable, CaseIterable {
    case business
    case technology
    case sports
    case culture
    case food
    case entertainment
    case science
    case health
    case travel
    case education
    
    var displayName: String {
        switch self {
        case .business:
            return Loc.Onboarding.interestBusiness
        case .technology:
            return Loc.Onboarding.interestTechnology
        case .sports:
            return Loc.Onboarding.interestSports
        case .culture:
            return Loc.Onboarding.interestCulture
        case .food:
            return Loc.Onboarding.interestFood
        case .entertainment:
            return Loc.Onboarding.interestEntertainment
        case .science:
            return Loc.Onboarding.interestScience
        case .health:
            return Loc.Onboarding.interestHealth
        case .travel:
            return Loc.Onboarding.interestTravel
        case .education:
            return Loc.Onboarding.interestEducation
        }
    }
    
    var icon: String {
        switch self {
        case .business:
            return "chart.bar.fill"
        case .technology:
            return "laptopcomputer"
        case .sports:
            return "sportscourt.fill"
        case .culture:
            return "theatermasks.fill"
        case .food:
            return "fork.knife"
        case .entertainment:
            return "tv.fill"
        case .science:
            return "atom"
        case .health:
            return "heart.fill"
        case .travel:
            return "airplane.departure"
        case .education:
            return "book.fill"
        }
    }
}

