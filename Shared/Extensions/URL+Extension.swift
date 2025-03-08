//
//  URL+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

public extension URL {

    func queryParams() -> [String: String]? {
        guard let urlComponents = URLComponents(
            url: self,
            resolvingAgainstBaseURL: false
        ) else { return nil }

        return urlComponents.queryItems?.reduce(into: [:], { $0[$1.name] = $1.value })
    }

    init?(string: String?) {
        guard let string, !string.isEmpty else { return nil }
        self = URL(string: string)!
    }
}
