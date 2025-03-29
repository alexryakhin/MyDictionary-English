//
//  String+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
#if os(iOS)
import class UIKit.UITextChecker
#elseif os(macOS)
import class AppKit.NSSpellChecker
#endif

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

public extension String {
    var isCorrect: Bool {
#if os(iOS)
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: self.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: self, range: range, startingAt: 0, wrap: false, language: "en")
        return misspelledRange.location == NSNotFound
#elseif os(macOS)
        let checker = NSSpellChecker.shared
        let misspelledRange = checker.checkSpelling(of: self, startingAt: 0)
        return misspelledRange.location == NSNotFound
#endif
    }
}

public extension String {

    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }

    /// Removes all tags enclosed in `< >`
    func removingHTMLTags() -> String {
        let pattern = "<[^>]+>" // Matches anything inside < >
        return self.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }
}
