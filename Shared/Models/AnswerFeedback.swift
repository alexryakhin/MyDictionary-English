//
//  AnswerFeedback.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/15/25.
//

import Foundation

enum AnswerFeedback: Hashable {
    case none
    case correct(Int)
    case incorrect(Int)
}
