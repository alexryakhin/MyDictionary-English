//
//  FilterCase.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

public enum FilterCase: String {
    case none
    case favorite
    case search

    public var title: String? {
        switch self {
        case .none:
            return nil
        case .favorite:
            return "Favorites"
        case .search:
            return "Found"
        }
    }
}
