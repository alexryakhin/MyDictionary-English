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
            return Loc.Words.Sorting.latestFirst
        case .earliest:
            return Loc.Words.Sorting.earliestFirst
        case .alphabetically:
            return Loc.Words.Sorting.alphabetically
        case .partOfSpeech:
            return Loc.Words.Sorting.byPartOfSpeech
        }
    }
}
