//
//  StudyTime.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum StudyTime: String, Codable, CaseIterable {
    case morning
    case afternoon
    case evening
    case flexible
    
    var displayName: String {
        switch self {
        case .morning:
            return Loc.Onboarding.studyTimeMorning
        case .afternoon:
            return Loc.Onboarding.studyTimeAfternoon
        case .evening:
            return Loc.Onboarding.studyTimeEvening
        case .flexible:
            return Loc.Onboarding.studyTimeFlexible
        }
    }
    
    var icon: String {
        switch self {
        case .morning:
            return "sunrise.fill"
        case .afternoon:
            return "sun.max.fill"
        case .evening:
            return "moon.stars.fill"
        case .flexible:
            return "clock.fill"
        }
    }
    
    var timeRange: String {
        switch self {
        case .morning:
            return Loc.Onboarding.studyTimeMorningRange
        case .afternoon:
            return Loc.Onboarding.studyTimeAfternoonRange
        case .evening:
            return Loc.Onboarding.studyTimeEveningRange
        case .flexible:
            return Loc.Onboarding.studyTimeFlexibleRange
        }
    }
    
    var defaultNotificationHour: Int {
        switch self {
        case .morning:
            return 8
        case .afternoon:
            return 14
        case .evening:
            return 20
        case .flexible:
            return 20
        }
    }
}

