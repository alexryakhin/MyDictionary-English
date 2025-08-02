//
//  FilterCase.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum FilterCase: String, CaseIterable {
    case none = "All Words"
    case favorite = "Favorite"
    case search = "Search"
    case tag = "Tag"
    case new = "New"
    case inProgress = "In Progress"
    case needsReview = "Needs Review"
    case mastered = "Mastered"
    
    static let availableCases: [FilterCase] = [.none, .favorite, .new, .inProgress, .needsReview, .mastered]
    
    var displayName: String {
        switch self {
        case .none:
            return "All Words"
        case .favorite:
            return "Favorite"
        case .search:
            return "Search"
        case .tag:
            return "Tag"
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
    
    var emptyStateTitle: String {
        switch self {
        case .none:
            return "No Words Yet"
        case .favorite:
            return "No Favorite Words"
        case .search:
            return "No Search Results"
        case .tag:
            return "No Tagged Words"
        case .new:
            return "No New Words"
        case .inProgress:
            return "No Words In Progress"
        case .needsReview:
            return "No Words Need Review"
        case .mastered:
            return "No Mastered Words"
        }
    }
    
    var emptyStateDescription: String {
        switch self {
        case .none:
            return "Start building your vocabulary by adding your first word"
        case .favorite:
            return "Tap the heart icon on any word to add it to your favorites"
        case .search:
            return "Try a different search term or add a new word"
        case .tag:
            return "Add tags to your words to organize them better"
        case .new:
            return "New words appear here when you add them to your list"
        case .inProgress:
            return "Words appear here as you practice them in quizzes"
        case .needsReview:
            return "Words that need more practice will appear here"
        case .mastered:
            return "Words you've mastered through practice will appear here"
        }
    }
    
    var emptyStateIcon: String {
        switch self {
        case .none:
            return "textformat"
        case .favorite:
            return "heart"
        case .search:
            return "magnifyingglass"
        case .tag:
            return "tag"
        case .new:
            return "plus.circle"
        case .inProgress:
            return "clock"
        case .needsReview:
            return "exclamationmark.triangle"
        case .mastered:
            return "checkmark.circle"
        }
    }
}
