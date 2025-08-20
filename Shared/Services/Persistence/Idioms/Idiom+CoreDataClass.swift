//
//  Idiom+CoreDataClass.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/19/25.
//
//

import Foundation
import CoreData

@objc(CDIdiom)
final class CDIdiom: NSManagedObject, Identifiable {
    @nonobjc class func fetchRequest() -> NSFetchRequest<CDIdiom> {
        return NSFetchRequest<CDIdiom>(entityName: "Idiom")
    }

    @NSManaged var definition: String?
    @NSManaged var difficultyScore: Int32
    @NSManaged var examples: Data?
    @NSManaged var id: UUID?
    @NSManaged var idiomItself: String?
    @NSManaged var isFavorite: Bool
    @NSManaged var languageCode: String?
    @NSManaged var timestamp: Date?
    @NSManaged var tags: NSSet?

    var examplesDecoded: [String] {
        guard let examples, let decodedData = try? JSONDecoder().decode([String].self, from: examples) else { return [] }
        return decodedData
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

    func updateExamples(_ examples: [String]) throws {
        let newExamplesData = try JSONEncoder().encode(examples)
        self.examples = newExamplesData
    }

    var tagsArray: [CDTag] {
        let set = tags as? Set<CDTag> ?? []
        return Array(set).sorted { $0.name ?? "" < $1.name ?? "" }
    }

    // coreModel property removed - using CDIdiom directly
}

// MARK: - Generated accessors for tags
extension CDIdiom {
    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: CDTag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: CDTag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)
}
