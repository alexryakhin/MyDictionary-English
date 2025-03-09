//
//  DefinitionsQueryParams.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

public struct DefinitionsQueryParams {
    public var limit: Int?
    public var includeRelated: Bool? = false
    public var includeTags: Bool? = false

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

    public init(limit: Int? = nil, includeRelated: Bool? = nil, includeTags: Bool? = nil) {
        self.limit = limit
        self.includeRelated = includeRelated
        self.includeTags = includeTags
    }
}
