import Foundation
import Combine
import SwiftUI

extension UserDefaults {
    enum Key: String {
        case reviewWorthyActionCount
        case lastReviewRequestAppVersion
    }

    func integer(forKey key: Key) -> Int {
        return integer(forKey: key.rawValue)
    }

    func string(forKey key: Key) -> String? {
        return string(forKey: key.rawValue)
    }

    func set(_ integer: Int, forKey key: Key) {
        set(integer, forKey: key.rawValue)
    }

    func set(_ object: Any?, forKey key: Key) {
        set(object, forKey: key.rawValue)
    }
}

extension NotificationCenter {
    var coreDataDidSavePublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .NSManagedObjectContextDidSave).receive(on: DispatchQueue.main)
    }
    var mergeChangesObjectIDsPublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .NSManagedObjectContextDidMergeChangesObjectIDs).receive(on: DispatchQueue.main)
    }
}

extension String {
    var trimmed: String {
        lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isCorrect: Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: self.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: self, range: range, startingAt: 0, wrap: false, language: "en")
        return misspelledRange.location == NSNotFound
    }
}

extension Collection {

    var isNotEmpty: Bool {
        !isEmpty
    }

    var nilIfEmpty: Self? {
        isNotEmpty ? self : nil
    }

    func removingDuplicates<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen: Set<T> = []
        var result: [Element] = []
        for element in self {
            if !seen.contains(element[keyPath: keyPath]) {
                seen.insert(element[keyPath: keyPath])
                result.append(element)
            }
        }
        return result
    }
}

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

extension Data {
    var prettyPrintedJSONString: String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
              let prettyJSON = String(data: data, encoding: .utf8)
        else { return nil }
        return prettyJSON
    }
}
