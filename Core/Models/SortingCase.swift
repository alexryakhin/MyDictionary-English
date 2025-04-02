//
//  SortingCase.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

public enum SortingCase: String, CaseIterable {
    case latest = "Latest first"
    case earliest = "Earliest first"
    case alphabetically = "Alphabetically"
    case partOfSpeech = "By Part of Speech"

    public static let idiomsSortingCases: [SortingCase] = [.latest, .earliest, .alphabetically]
}
