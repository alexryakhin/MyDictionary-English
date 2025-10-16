//
//  CEFRLevel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum CEFRLevel: String, Codable, CaseIterable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"
    case c2 = "C2"
    
    var displayName: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .a1:
            return Loc.Onboarding.cefrLevelA1Description
        case .a2:
            return Loc.Onboarding.cefrLevelA2Description
        case .b1:
            return Loc.Onboarding.cefrLevelB1Description
        case .b2:
            return Loc.Onboarding.cefrLevelB2Description
        case .c1:
            return Loc.Onboarding.cefrLevelC1Description
        case .c2:
            return Loc.Onboarding.cefrLevelC2Description
        }
    }
    
    var level: Int {
        switch self {
        case .a1: return 1
        case .a2: return 2
        case .b1: return 3
        case .b2: return 4
        case .c1: return 5
        case .c2: return 6
        }
    }
}

