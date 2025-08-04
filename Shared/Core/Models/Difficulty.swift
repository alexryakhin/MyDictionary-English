//
//  Difficulty.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

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
    
    var color: String {
        switch self {
        case .new:
            return "secondary"
        case .inProgress:
            return "orange"
        case .needsReview:
            return "red"
        case .mastered:
            return "green"
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
} 