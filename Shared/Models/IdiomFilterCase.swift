//
//  IdiomFilterCase.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum IdiomFilterCase: String, CaseIterable {
    case none = "all_idioms"
    case favorite = "favorite"
    case search = "search"

    static let availableCases: [IdiomFilterCase] = [.none, .favorite]

    var displayName: String {
        switch self {
        case .none:
            return Loc.IdiomFilters.allIdioms.localized
        case .favorite:
            return Loc.IdiomFilters.favorite.localized
        case .search:
            return Loc.IdiomFilters.search.localized
        }
    }
    
    var emptyStateTitle: String {
        switch self {
        case .none:
            return Loc.IdiomFilters.noIdiomsYet.localized
        case .favorite:
            return Loc.IdiomFilters.noFavoriteWords.localized
        case .search:
            return Loc.IdiomFilters.noSearchResults.localized
        }
    }
    
    var emptyStateDescription: String {
        switch self {
        case .none:
            return Loc.IdiomFilters.startImprovingVocabulary.localized
        case .favorite:
            return Loc.IdiomFilters.tapHeartIconToAddFavorites.localized
        case .search:
            return Loc.IdiomFilters.tryDifferentSearchTerm.localized
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
