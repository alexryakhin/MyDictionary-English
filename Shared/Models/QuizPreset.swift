//
//  QuizPreset.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/15/25.
//

import Foundation

struct QuizPreset: Hashable {

    enum Mode {
        case all
        case wordsOnly
        case idiomsOnly
    }

    let itemCount: Int
    let hardItemsOnly: Bool
    let mode: Mode
}
