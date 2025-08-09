//
//  Difficulty.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import SwiftUI

enum Difficulty: String, CaseIterable {
    case new = "new"
    case inProgress = "inProgress"
    case needsReview = "needsReview"
    case mastered = "mastered"
    
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
    
    var level: Int32 {
        switch self {
        case .new:
            return 0
        case .inProgress:
            return 1
        case .needsReview:
            return 2
        case .mastered:
            return 3
        }
    }

    var imageName: String {
        switch self {
        case .new:
            return "sparkles"
        case .inProgress:
            return "clock.fill"
        case .needsReview:
            return "exclamationmark.triangle.fill"
        case .mastered:
            return "checkmark.circle.fill"
        }
    }
}
