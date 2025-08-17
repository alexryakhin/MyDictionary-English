//
//  SortingCase.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum SortingCase: String, CaseIterable {
    case latest = "latest_first"
    case earliest = "earliest_first"
    case alphabetically = "alphabetically"
    case partOfSpeech = "by_part_of_speech"

    static let idiomsSortingCases: [SortingCase] = [.latest, .earliest, .alphabetically]
    
    var displayName: String {
        switch self {
        case .latest:
            return Loc.Sorting.latestFirst.localized
        case .earliest:
            return Loc.Sorting.earliestFirst.localized
        case .alphabetically:
            return Loc.Sorting.alphabetically.localized
        case .partOfSpeech:
            return Loc.Sorting.byPartOfSpeech.localized
        }
    }
}
