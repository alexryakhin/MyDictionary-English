//
//  FilterCase.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum FilterCase: String, CaseIterable {
    case none = "All Words"
    case favorite = "Favorite"
    case search = "Search"
    case tag = "Tag"
    
    static let availableCases: [FilterCase] = [.none, .favorite]
    
    var displayName: String {
        switch self {
        case .none:
            return "All Words"
        case .favorite:
            return "Favorite"
        case .search:
            return "Search"
        case .tag:
            return "Tag"
        }
    }
}
