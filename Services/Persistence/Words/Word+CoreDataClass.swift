//
//  Word+CoreDataClass.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/19/25.
//
//

import Foundation
import CoreData
import Core

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
    @NSManaged var isFavorite: Bool
    @NSManaged var examples: Data?

    var examplesDecoded: [String] {
        guard let examples,
              let decodedData = try? JSONDecoder().decode([String].self, from: examples)
        else { return [] }
        return decodedData
    }

    func updateExamples(_ examples: [String]) throws {
        let newExamplesData = try JSONEncoder().encode(examples)
        self.examples = newExamplesData
    }

    var coreModel: Word? {
        guard let wordItself, let definition, let partOfSpeech, let id, let timestamp else { return nil }
        return Word(
            word: wordItself,
            definition: definition,
            partOfSpeech: .init(rawValue: partOfSpeech) ?? .unknown,
            phonetic: phonetic ?? .empty,
            id: id.uuidString,
            timestamp: timestamp,
            examples: examplesDecoded,
            isFavorite: isFavorite
        )
    }
}
