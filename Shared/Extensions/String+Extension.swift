//
//  String+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

public extension String {

    init(_ substrings: String?..., separator: String = "") {
        self = substrings.compactMap { $0 }.joined(separator: separator)
    }

    init(_ substrings: [String?], separator: String = "") {
        self = substrings.compactMap { $0 }.joined(separator: separator)
    }

    static func join(_ substrings: [String?], separator: String = "") -> String {
        return String(substrings, separator: separator)
    }

    static func join(_ substrings: String?..., separator: String = "") -> String {
        return String(substrings, separator: separator)
    }

    static var empty: String {
        return String()
    }

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var removingSpaces: String {
        replacingOccurrences(of: " ", with: "")
    }

    var isNotEmpty: Bool { !isEmpty }
    var nilIfEmpty: String? { isNotEmpty ? self : nil }
}

public extension Optional where Wrapped == String {
    var orEmpty: String { self ?? "" }
    var isEmpty: Bool { self?.isEmpty ?? true }
}
