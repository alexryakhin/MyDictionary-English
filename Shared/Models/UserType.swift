//
//  UserType.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum UserType: String, Codable, CaseIterable {
    case student
    case professional
    case hobbyist
    case other
    
    var displayName: String {
        switch self {
        case .student:
            return Loc.Onboarding.userTypeStudent
        case .professional:
            return Loc.Onboarding.userTypeProfessional
        case .hobbyist:
            return Loc.Onboarding.userTypeHobbyist
        case .other:
            return Loc.Onboarding.userTypeOther
        }
    }
    
    var icon: String {
        switch self {
        case .student:
            return "graduationcap.fill"
        case .professional:
            return "briefcase.fill"
        case .hobbyist:
            return "book.fill"
        case .other:
            return "person.fill"
        }
    }
    
    var description: String {
        switch self {
        case .student:
            return Loc.Onboarding.userTypeStudentDescription
        case .professional:
            return Loc.Onboarding.userTypeProfessionalDescription
        case .hobbyist:
            return Loc.Onboarding.userTypeHobbyistDescription
        case .other:
            return Loc.Onboarding.userTypeOtherDescription
        }
    }
}

