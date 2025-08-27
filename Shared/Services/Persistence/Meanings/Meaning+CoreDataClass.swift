//
//  Meaning+CoreDataClass.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/19/25.
//
//

import Foundation
import CoreData

@objc(CDMeaning)
final class CDMeaning: NSManagedObject, Identifiable {
    @nonobjc class func fetchRequest() -> NSFetchRequest<CDMeaning> {
        return NSFetchRequest<CDMeaning>(entityName: "Meaning")
    }

    @NSManaged var id: UUID?
    @NSManaged var definition: String?
    @NSManaged var examples: Data?
    @NSManaged var order: Int32
    @NSManaged var timestamp: Date?
    @NSManaged var word: CDWord?

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
    
    /// Updates this meaning with new data
    func update(definition: String, examples: [String], order: Int32) throws {
        self.definition = definition
        self.order = order
        try updateExamples(examples)
    }
    
    /// Creates a new meaning with the provided data
    static func create(
        in context: NSManagedObjectContext,
        definition: String,
        examples: [String] = [],
        order: Int32 = 0,
        for word: CDWord
    ) throws -> CDMeaning {
        let meaning = CDMeaning(context: context)
        meaning.id = UUID()
        meaning.definition = definition
        meaning.order = order
        meaning.timestamp = Date()
        meaning.word = word
        try meaning.updateExamples(examples)
        return meaning
    }
}