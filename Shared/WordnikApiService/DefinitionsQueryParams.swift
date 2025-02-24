//
//  DefinitionsQueryParams.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/24/25.
//

import Foundation

struct DefinitionsQueryParams {
    var limit: Int?
    var includeRelated: Bool? = false
    var includeTags: Bool? = false

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let limit = limit {
            items.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }
        if let includeRelated = limit {
            items.append(URLQueryItem(name: "includeRelated", value: "\(includeRelated)"))
        }
        if let includeTags = limit {
            items.append(URLQueryItem(name: "includeTags", value: "\(includeTags)"))
        }
        return items
    }
}
