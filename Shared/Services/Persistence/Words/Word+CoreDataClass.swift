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
    @NSManaged var definition: String? // Keep for migration, will be deprecated
    @NSManaged var partOfSpeech: String?
    @NSManaged var phonetic: String?
    @NSManaged var id: UUID?
    @NSManaged var timestamp: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var isFavorite: Bool
    @NSManaged var examples: Data? // Keep for migration, will be deprecated
    @NSManaged var tags: NSSet?
    @NSManaged var difficultyScore: Int32
    @NSManaged var languageCode: String?
    @NSManaged var isSynced: Bool
    @NSManaged var meanings: NSSet?

    // MARK: - Legacy Properties (for migration)
    var examplesDecoded: [String] {
        guard let examples,
              let decodedData = try? JSONDecoder().decode([String].self, from: examples)
        else { return [] }
        return decodedData
    }

    var partOfSpeechDecoded: PartOfSpeech {
        PartOfSpeech(rawValue: partOfSpeech)
    }

    // MARK: - New Meanings-based Properties
    
    /// Returns meanings sorted by order
    var meaningsArray: [CDMeaning] {
        let set = meanings as? Set<CDMeaning> ?? []
        return Array(set).sorted { $0.order < $1.order }
    }
    
    /// Returns the primary (first) meaning
    var primaryMeaning: CDMeaning? {
        return meaningsArray.first
    }
    
    /// Returns the primary definition (from first meaning)
    var primaryDefinition: String? {
        return primaryMeaning?.definition
    }
    
    /// Returns examples from the primary meaning
    var primaryExamples: [String] {
        return primaryMeaning?.examplesDecoded ?? []
    }
    
    /// Returns all examples from all meanings
    var allExamples: [String] {
        return meaningsArray.flatMap { $0.examplesDecoded }
    }
    
    /// Returns true if this word is an idiom
    var isIdiomType: Bool {
        return partOfSpeechDecoded == .idiom
    }
    
    /// Returns true if this word is a phrase
    var isPhraseType: Bool {
        return partOfSpeechDecoded == .phrase
    }
    
    /// Returns true if this word is an expression (idiom or phrase)
    var isExpression: Bool {
        return partOfSpeechDecoded.isExpression
    }
    
    /// Returns true if this is a regular word (not an expression)
    var isRegularWord: Bool {
        return !isExpression
    }

    // MARK: - Existing Computed Properties
    
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

    // MARK: - Helper Methods
    
    func updateExamples(_ examples: [String]) throws {
        let newExamplesData = try JSONEncoder().encode(examples)
        self.examples = newExamplesData
    }
    
    /// Adds a new meaning to this word
    func addMeaning(definition: String, examples: [String] = [], order: Int32? = nil) throws -> CDMeaning {
        guard let context = managedObjectContext else {
            throw CoreError.storageError(.dataCorrupted)
        }
        
        let meaningOrder = order ?? Int32(meaningsArray.count)
        let meaning = try CDMeaning.create(
            in: context,
            definition: definition,
            examples: examples,
            order: meaningOrder,
            for: self
        )
        
        addToMeanings(meaning)
        return meaning
    }
    
    /// Removes a meaning from this word
    func removeMeaning(_ meaning: CDMeaning) {
        removeFromMeanings(meaning)
        managedObjectContext?.delete(meaning)
    }
    
    /// Updates the order of meanings
    func reorderMeanings() {
        let sortedMeanings = meaningsArray
        for (index, meaning) in sortedMeanings.enumerated() {
            meaning.order = Int32(index)
        }
    }
}

// MARK: - Generated accessors for meanings
extension CDWord {
    @objc(addMeaningsObject:)
    @NSManaged public func addToMeanings(_ value: CDMeaning)

    @objc(removeMeaningsObject:)
    @NSManaged public func removeFromMeanings(_ value: CDMeaning)

    @objc(addMeanings:)
    @NSManaged public func addToMeanings(_ values: NSSet)

    @objc(removeMeanings:)
    @NSManaged public func removeFromMeanings(_ values: NSSet)
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
