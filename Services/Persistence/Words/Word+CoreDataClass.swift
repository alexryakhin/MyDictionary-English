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
    @NSManaged var isFavorite: Bool
    @NSManaged var examples: Data?
    @NSManaged var tags: NSSet?
    @NSManaged var difficultyLevel: Int32

    var examplesDecoded: [String] {
        guard let examples,
              let decodedData = try? JSONDecoder().decode([String].self, from: examples)
        else { return [] }
        return decodedData
    }

    var partOfSpeechDecoded: PartOfSpeech {
        PartOfSpeech(rawValue: partOfSpeech ?? "") ?? .unknown
    }
    
    var difficultyLabel: String {
        switch difficultyLevel {
        case 0:
            return "new"
        case 1:
            return "inProgress"
        case 2:
            return "needsReview"
        case 3:
            return "mastered"
        default:
            return "new"
        }
    }
    
    var difficultyColor: Color {
        switch difficultyLevel {
        case 0:
            return .secondary
        case 1:
            return .orange
        case 2:
            return .red
        case 3:
            return .green
        default:
            return .secondary
        }
    }
    
    var shouldShowDifficultyLabel: Bool {
        return difficultyLevel > 0
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
