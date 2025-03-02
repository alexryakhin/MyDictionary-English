//
//  URL+Extension.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 10/6/24.
//

import Foundation

extension URL {

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
