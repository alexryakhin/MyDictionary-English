//
//  SortingCase.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum SortingCase: String, CaseIterable {
    case latest = "Latest first"
    case earliest = "Earliest first"
    case alphabetically = "Alphabetically"
    case partOfSpeech = "By Part of Speech"

    static let idiomsSortingCases: [SortingCase] = [.latest, .earliest, .alphabetically]
}
