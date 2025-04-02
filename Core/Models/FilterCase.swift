//
//  FilterCase.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

public enum FilterCase: String {
    case none = "Disabled"
    case favorite = "Favorite"
    case search = "Search"

    public static let availableCases: [FilterCase] = [.none, .favorite]
}
