//
//  Difficulty.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import SwiftUI

enum Difficulty: Hashable, CaseIterable {
    case new
    case inProgress
    case needsReview
    case mastered
    
    var displayName: String {
        switch self {
        case .new:
            return "New"
        case .inProgress:
            return "In Progress"
        case .needsReview:
            return "Needs Review"
        case .mastered:
            return "Mastered"
        }
    }
    
    var color: Color {
        switch self {
        case .new: .blue
        case .inProgress: .orange
        case .needsReview: .red
        case .mastered: .accent
        }
    }

    var imageName: String {
        switch self {
        case .new:
            return "sparkles"
        case .inProgress:
            return "hourglass"
        case .needsReview:
            return "exclamationmark.triangle"
        case .mastered:
            return "checkmark.circle"
        }
    }
    
    // Initialize from score
    init(score: Int) {
        if score < 0 {
            self = .needsReview
        } else if score >= 1 && score <= 49 {
            self = .inProgress
        } else if score >= 50 {
            self = .mastered
        } else {
            self = .new
        }
    }
}
