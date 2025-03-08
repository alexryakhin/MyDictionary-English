//
//  Idiom+CoreDataClass.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/19/25.
//
//

import Foundation
import CoreData
import Core

@objc(Idiom)
final class Idiom: NSManagedObject, Identifiable {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Idiom> {
        return NSFetchRequest<Idiom>(entityName: "Idiom")
    }

    @NSManaged var definition: String?
    @NSManaged var examples: Data?
    @NSManaged var id: UUID?
    @NSManaged var idiomItself: String?
    @NSManaged var isFavorite: Bool
    @NSManaged var timestamp: Date?

    var examplesDecoded: [String] {
        guard let examples, let decodedData = try? JSONDecoder().decode([String].self, from: examples) else { return [] }
        return decodedData
    }

    func removeExample(_ example: String) throws {
        var examples = examplesDecoded
        guard let index = examples.firstIndex(of: example) else {
            throw CoreError.internalError(.removingIdiomExampleFailed)
        }
        examples.remove(at: index)
        let newExamplesData = try JSONEncoder().encode(examples)
        self.examples = newExamplesData
    }

    func removeExample(atOffsets offsets: IndexSet) throws {
        var examples = examplesDecoded
        examples.remove(atOffsets: offsets)

        let newExamplesData = try JSONEncoder().encode(examples)
        self.examples = newExamplesData
    }

    func addExample(_ example: String) throws {
        guard !example.isEmpty else {
            throw CoreError.internalError(.savingIdiomExampleFailed)
        }
        let newExamples = examplesDecoded + [example]
        let newExamplesData = try JSONEncoder().encode(newExamples)
        self.examples = newExamplesData
    }

    var coreModel: CoreIdiom? {
        guard let idiomItself, let definition, let id, let timestamp else { return nil }
        return CoreIdiom(
            idiom: idiomItself,
            definition: definition,
            id: id,
            timestamp: timestamp,
            examples: examplesDecoded,
            isFavorite: isFavorite
        )
    }
}
