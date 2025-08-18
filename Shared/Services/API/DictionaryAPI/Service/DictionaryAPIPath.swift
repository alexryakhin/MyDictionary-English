//
//  DictionaryAPIPath.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

enum DictionaryAPIPath: APIPath {
    case definitions(word: String)

    var path: String {
        switch self {
        case .definitions(let word): return "/\(word)"
        }
    }

    var queryParams: [URLQueryItem]? {
        switch self {
        case .definitions: return nil
        }
    }
}
