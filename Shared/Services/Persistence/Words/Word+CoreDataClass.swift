//
//  Word+CoreDataClass.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/19/25.
//
//

import Foundation
import CoreData
import SwiftUI // Added for Color

@objc(CDWord)
final class CDWord: NSManagedObject, Identifiable {
    @nonobjc class func fetchRequest() -> NSFetchRequest<CDWord> {
        return NSFetchRequest<CDWord>(entityName: "Word")
    }

    @NSManaged var wordItself: String?
    @NSManaged var definition: String?
    @NSManaged var partOfSpeech: String?
    @NSManaged var phonetic: String?
    @NSManaged var id: UUID?
    @NSManaged var timestamp: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var isFavorite: Bool
    @NSManaged var examples: Data?
    @NSManaged var tags: NSSet?
    @NSManaged var difficultyScore: Int32
    @NSManaged var languageCode: String?
    @NSManaged var isSynced: Bool

    var examplesDecoded: [String] {
        guard let examples,
              let decodedData = try? JSONDecoder().decode([String].self, from: examples)
        else { return [] }
        return decodedData
    }

    var partOfSpeechDecoded: PartOfSpeech {
        PartOfSpeech(rawValue: partOfSpeech)
    }

    // Computed property for difficulty level based on score
    var difficultyLevel: Difficulty {
        return Difficulty(score: Int(difficultyScore))
    }

    var shouldShowDifficultyLabel: Bool {
        return difficultyLevel != .new
    }

    var languageDisplayName: String {
        guard
            let languageCode,
            let language = Locale.current.localizedString(forLanguageCode: languageCode)
        else { return "Unknown" }
        return language.capitalized
    }
    
    var shouldShowLanguageLabel: Bool {
        return languageCode?.nilIfEmpty != nil && languageCode != "en"
    }

    var tagsArray: [CDTag] {
        let set = tags as? Set<CDTag> ?? []
        return Array(set).sorted { $0.name ?? "" < $1.name ?? "" }
    }

    func updateExamples(_ examples: [String]) throws {
        let newExamplesData = try JSONEncoder().encode(examples)
        self.examples = newExamplesData
    }
}

// MARK: - Generated accessors for tags
extension CDWord {
    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: CDTag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: CDTag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)
}
