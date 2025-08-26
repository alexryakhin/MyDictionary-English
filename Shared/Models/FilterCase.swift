//
//  FilterCase.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum FilterCase: CaseIterable {

    enum ItemType {
        case words
        case idioms
    }

    case none
    case favorite
    case search
    case tag
    case new
    case inProgress
    case needsReview
    case mastered
    
    static let availableCases: [FilterCase] = [.none, .favorite, .new, .inProgress, .needsReview, .mastered]
    
    var displayName: String {
        switch self {
        case .none:
            return Loc.FilterDisplay.all
        case .favorite:
            return Loc.FilterDisplay.favorite
        case .search:
            return Loc.FilterDisplay.search
        case .tag:
            return Loc.FilterDisplay.tag
        case .new:
            return Loc.FilterDisplay.new
        case .inProgress:
            return Loc.FilterDisplay.inProgress
        case .needsReview:
            return Loc.FilterDisplay.needsReview
        case .mastered:
            return Loc.FilterDisplay.mastered
        }
    }
    
    func emptyStateTitle(for itemType: ItemType) -> String {
        switch itemType {
        case .words:
            switch self {
            case .none:
                return Loc.FilterDisplay.noWordsYet
            case .favorite:
                return Loc.FilterDisplay.noFavoriteWords
            case .search:
                return Loc.FilterDisplay.noSearchResults
            case .tag:
                return Loc.FilterDisplay.noTaggedWords
            case .new:
                return Loc.FilterDisplay.noNewWords
            case .inProgress:
                return Loc.FilterDisplay.noWordsInProgress
            case .needsReview:
                return Loc.FilterDisplay.noWordsNeedReview
            case .mastered:
                return Loc.FilterDisplay.noMasteredWords
            }
        case .idioms:
            switch self {
            case .none:
                return Loc.FilterDisplay.noIdiomsYet
            case .favorite:
                return Loc.FilterDisplay.noFavoriteIdioms
            case .search:
                return Loc.FilterDisplay.noSearchResults
            case .tag:
                return Loc.FilterDisplay.noTaggedIdioms
            case .new:
                return Loc.FilterDisplay.noNewIdioms
            case .inProgress:
                return Loc.FilterDisplay.noIdiomsInProgress
            case .needsReview:
                return Loc.FilterDisplay.noIdiomsNeedReview
            case .mastered:
                return Loc.FilterDisplay.noMasteredIdioms
            }
        }
    }
    
    func emptyStateDescription(for itemType: ItemType) -> String {
        switch itemType {
        case .words:
            switch self {
            case .none:
                return Loc.FilterDisplay.startBuildingVocabulary
            case .favorite:
                return Loc.FilterDisplay.tapHeartIconToAddFavorites
            case .search:
                return Loc.FilterDisplay.tryDifferentSearchTerm
            case .tag:
                return Loc.FilterDisplay.addTagsToOrganize
            case .new:
                return Loc.FilterDisplay.newWordsAppearHere
            case .inProgress:
                return Loc.FilterDisplay.wordsAppearHereAsYouPractice
            case .needsReview:
                return Loc.FilterDisplay.wordsNeedMorePractice
            case .mastered:
                return Loc.FilterDisplay.wordsNeedMorePractice
            }
        case .idioms:
            switch self {
            case .none:
                return Loc.FilterDisplay.startBuildingVocabularyIdioms
            case .favorite:
                return Loc.FilterDisplay.tapHeartIconToAddFavoritesIdioms
            case .search:
                return Loc.FilterDisplay.tryDifferentSearchTermIdioms
            case .tag:
                return Loc.FilterDisplay.addTagsToOrganizeIdioms
            case .new:
                return Loc.FilterDisplay.newIdiomsAppearHere
            case .inProgress:
                return Loc.FilterDisplay.idiomsAppearHereAsYouPractice
            case .needsReview:
                return Loc.FilterDisplay.idiomsNeedMorePractice
            case .mastered:
                return Loc.FilterDisplay.idiomsNeedMorePractice
            }
        }
    }

    func emptyStateIcon(for itemType: ItemType) -> String {
        switch self {
        case .none:
            switch itemType {
            case .words: return "textformat"
            case .idioms: return "scroll"
            }
        case .favorite:
            return "heart"
        case .search:
            return "magnifyingglass"
        case .tag:
            return "tag"
        case .new:
            return "plus.circle"
        case .inProgress:
            return "hourglass"
        case .needsReview:
            return "exclamationmark.triangle"
        case .mastered:
            return "checkmark.circle"
        }
    }
}
