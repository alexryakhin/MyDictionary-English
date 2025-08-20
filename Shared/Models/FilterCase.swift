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
            return Loc.FilterDisplay.all.localized
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
    
    func emptyStateTitle(for itemType: ItemType) -> String {
        switch itemType {
        case .words:
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
        case .idioms:
            switch self {
            case .none:
                return Loc.FilterDisplay.noIdiomsYet.localized
            case .favorite:
                return Loc.FilterDisplay.noFavoriteIdioms.localized
            case .search:
                return Loc.FilterDisplay.noSearchResults.localized
            case .tag:
                return Loc.FilterDisplay.noTaggedIdioms.localized
            case .new:
                return Loc.FilterDisplay.noNewIdioms.localized
            case .inProgress:
                return Loc.FilterDisplay.noIdiomsInProgress.localized
            case .needsReview:
                return Loc.FilterDisplay.noIdiomsNeedReview.localized
            case .mastered:
                return Loc.FilterDisplay.noMasteredIdioms.localized
            }
        }
    }
    
    func emptyStateDescription(for itemType: ItemType) -> String {
        switch itemType {
        case .words:
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
        case .idioms:
            switch self {
            case .none:
                return Loc.FilterDisplay.startBuildingVocabularyIdioms.localized
            case .favorite:
                return Loc.FilterDisplay.tapHeartIconToAddFavoritesIdioms.localized
            case .search:
                return Loc.FilterDisplay.tryDifferentSearchTermIdioms.localized
            case .tag:
                return Loc.FilterDisplay.addTagsToOrganizeIdioms.localized
            case .new:
                return Loc.FilterDisplay.newIdiomsAppearHere.localized
            case .inProgress:
                return Loc.FilterDisplay.idiomsAppearHereAsYouPractice.localized
            case .needsReview:
                return Loc.FilterDisplay.idiomsNeedMorePractice.localized
            case .mastered:
                return Loc.FilterDisplay.idiomsNeedMorePractice.localized
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
