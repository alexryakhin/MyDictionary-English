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
            return Loc.FilterDisplay.allWords.localized
        case .favorite:
            return Loc.FilterDisplay.favorite.localized
        case .search:
            return Loc.FilterDisplay.search.localized
        case .tag:
            return Loc.FilterDisplay.tag.localized
        case .new:
            return Loc.FilterDisplay.new.localized
        case .inProgress:
            return Loc.FilterDisplay.inProgress.localized
        case .needsReview:
            return Loc.FilterDisplay.needsReview.localized
        case .mastered:
            return Loc.FilterDisplay.mastered.localized
        }
    }
    
    var emptyStateTitle: String {
        switch self {
        case .none:
            return Loc.FilterDisplay.noWordsYet.localized
        case .favorite:
            return Loc.FilterDisplay.noFavoriteWords.localized
        case .search:
            return Loc.FilterDisplay.noSearchResults.localized
        case .tag:
            return Loc.FilterDisplay.noTaggedWords.localized
        case .new:
            return Loc.FilterDisplay.noNewWords.localized
        case .inProgress:
            return Loc.FilterDisplay.noWordsInProgress.localized
        case .needsReview:
            return Loc.FilterDisplay.noWordsNeedReview.localized
        case .mastered:
            return Loc.FilterDisplay.noMasteredWords.localized
        }
    }
    
    var emptyStateDescription: String {
        switch self {
        case .none:
            return Loc.FilterDisplay.startBuildingVocabulary.localized
        case .favorite:
            return Loc.FilterDisplay.tapHeartIconToAddFavorites.localized
        case .search:
            return Loc.FilterDisplay.tryDifferentSearchTerm.localized
        case .tag:
            return Loc.FilterDisplay.addTagsToOrganize.localized
        case .new:
            return Loc.FilterDisplay.newWordsAppearHere.localized
        case .inProgress:
            return Loc.FilterDisplay.wordsAppearHereAsYouPractice.localized
        case .needsReview:
            return Loc.FilterDisplay.wordsNeedMorePractice.localized
        case .mastered:
            return Loc.FilterDisplay.wordsNeedMorePractice.localized
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
