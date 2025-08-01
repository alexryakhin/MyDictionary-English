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

extension String {

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

extension Optional where Wrapped == String {
    var orEmpty: String { self ?? "" }
    var isEmpty: Bool { self?.isEmpty ?? true }
}

extension String {
    var isCorrect: Bool {
#if os(iOS)
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: self.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: self, range: range, startingAt: 0, wrap: false, language: "en")
        return misspelledRange.location == NSNotFound
#elseif os(macOS)
        let checker = NSSpellChecker.shared
        var wordCount: Int = 0
        let range = checker.checkSpelling(of: self, startingAt: 0, language: "en", wrap: false, inSpellDocumentWithTag: 0, wordCount: &wordCount)
        return range.location == NSNotFound
#endif
    }

    var isValidEnglishWordOrPhrase: Bool {
        // 1. Must have at least two characters
        guard self.count > 1 else { return false }

        // 2. Reject camelCase and PascalCase (e.g., "newWord", "NewWord")
        let camelCasePattern = #"(?<=[a-z])(?=[A-Z])"#
        if self.range(of: camelCasePattern, options: .regularExpression) != nil {
            return false
        }

        // 3. Check if each word is a valid English word and only contains letters
        let words = self.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !words.isEmpty else { return false }

        let letterCharacterSet = CharacterSet.letters

        for word in words {
            if word.count < 2 { return false } // too short
            if word.rangeOfCharacter(from: letterCharacterSet.inverted) != nil { return false } // contains digits or symbols
            if !word.isCorrect { return false } // not an English word
        }

        return true
    }
}

extension String {

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
