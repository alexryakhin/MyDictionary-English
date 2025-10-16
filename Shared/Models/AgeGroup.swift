//
//  AgeGroup.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum AgeGroup: String, Codable, CaseIterable {
    case teen = "13-17"
    case youngAdult = "18-24"
    case adult = "25-34"
    case midlife = "35-44"
    case mature = "45-54"
    case senior = "55+"
    
    var displayName: String {
        return rawValue
    }
    
    var emoji: String {
        switch self {
        case .teen:
            return "🎒"
        case .youngAdult:
            return "🎓"
        case .adult:
            return "💼"
        case .midlife:
            return "👔"
        case .mature:
            return "📚"
        case .senior:
            return "🌟"
        }
    }
}

