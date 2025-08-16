//
//  IdiomFilterCase.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum IdiomFilterCase: String, CaseIterable {
    case none = "All Idioms"
    case favorite = "Favorite"
    case search = "Search"

    static let availableCases: [IdiomFilterCase] = [.none, .favorite]

    var displayName: String {
        switch self {
        case .none:
            return "All Idioms"
        case .favorite:
            return "Favorite"
        case .search:
            return "Search"
        }
    }
    
    var emptyStateTitle: String {
        switch self {
        case .none:
            return "No Idioms Yet"
        case .favorite:
            return "No Favorite Words"
        case .search:
            return "No Search Results"
        }
    }
    
    var emptyStateDescription: String {
        switch self {
        case .none:
            return "Start improving your vocabulary by adding your first idiom"
        case .favorite:
            return "Tap the heart icon on any idiom to add it to your favorites"
        case .search:
            return "Try a different search term or add a new idiom"
        }
    }
    
    var emptyStateIcon: String {
        switch self {
        case .none:
            return "scroll"
        case .favorite:
            return "heart"
        case .search:
            return "magnifyingglass"
        }
    }
}
