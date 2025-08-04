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
    @NSManaged var examples: Data?
    @NSManaged var id: UUID?
    @NSManaged var idiomItself: String?
    @NSManaged var isFavorite: Bool
    @NSManaged var timestamp: Date?

    var examplesDecoded: [String] {
        guard let examples, let decodedData = try? JSONDecoder().decode([String].self, from: examples) else { return [] }
        return decodedData
    }

    func updateExamples(_ examples: [String]) throws {
        let newExamplesData = try JSONEncoder().encode(examples)
        self.examples = newExamplesData
    }

    // coreModel property removed - using CDIdiom directly
}
