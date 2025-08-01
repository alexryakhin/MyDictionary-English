//
//  FilterCase.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum FilterCase: String {
    case none = "Disabled"
    case favorite = "Favorite"
    case search = "Search"

    static let availableCases: [FilterCase] = [.none, .favorite]
}
