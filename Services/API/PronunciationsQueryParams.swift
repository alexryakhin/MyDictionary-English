//
//  DefinitionsQueryParams.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

public struct PronunciationsQueryParams {
    public var limit: Int?

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [URLQueryItem(name: "typeFormat", value: "IPA")]
        if let limit = limit {
            items.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }
        return items
    }

    public init(limit: Int? = nil) {
        self.limit = limit
    }
}
