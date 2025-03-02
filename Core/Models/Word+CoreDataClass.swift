//
//  Word+CoreDataClass.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/19/25.
//
//

import Foundation
import CoreData

@objc(Word)
class Word: NSManagedObject, Identifiable {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Word> {
        return NSFetchRequest<Word>(entityName: "Word")
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

    func removeExample(_ example: String) throws {
        var examples = examplesDecoded
        guard let index = examples.firstIndex(of: example) else {
            throw CoreError.internalError(.removingWordExampleFailed)
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
            throw CoreError.internalError(.savingWordExampleFailed)
        }
        let newExamples = examplesDecoded + [example]
        let newExamplesData = try JSONEncoder().encode(newExamples)
        self.examples = newExamplesData
    }
}
