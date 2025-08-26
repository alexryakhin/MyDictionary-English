//
//  Word.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import FirebaseFirestore
import CoreData

struct WordMeaning: Codable, Hashable, Identifiable {
    let id: String
    var definition: String
    var examples: [String]
    var order: Int
    let timestamp: Date
    
    init(id: String = UUID().uuidString, definition: String, examples: [String] = [], order: Int = 0, timestamp: Date = Date()) {
        self.id = id
        self.definition = definition
        self.examples = examples
        self.order = order
        self.timestamp = timestamp
    }
}

struct Word: Codable, Identifiable {
    let id: String
    let wordItself: String
    let meanings: [WordMeaning] // New: Multiple meanings support
    let partOfSpeech: String
    let phonetic: String?
    let tags: [String]
    let difficultyScore: Int
    let languageCode: String
    let isFavorite: Bool
    let timestamp: Date // Created at date
    let updatedAt: Date // Last updated date
    let isSynced: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case wordItself
        case meanings
        case partOfSpeech
        case phonetic
        case tags
        case difficultyScore
        case languageCode
        case isFavorite
        case timestamp
        case updatedAt
        case isSynced
    }
    
    // MARK: - Computed Properties for Backward Compatibility
    
    /// Primary meaning (first meaning)
    var primaryMeaning: WordMeaning? {
        return meanings.first
    }
    
    /// Primary definition for backward compatibility
    var definition: String {
        return primaryMeaning?.definition ?? ""
    }
    
    /// Primary examples for backward compatibility  
    var examples: [String] {
        return primaryMeaning?.examples ?? []
    }
    
    /// All examples from all meanings
    var allExamples: [String] {
        return meanings.flatMap { $0.examples }
    }
    
    /// Sorted meanings by order
    var sortedMeanings: [WordMeaning] {
        return meanings.sorted { $0.order < $1.order }
    }
    
    // Computed property for difficulty level based on score
    var difficultyLevel: Difficulty {
        return Difficulty(score: difficultyScore)
    }

    func toFirestoreDictionary() -> [String: Any] {
        // Convert meanings to Firestore format
        let meaningsData = meanings.map { meaning in
            return [
                "id": meaning.id,
                "definition": meaning.definition,
                "examples": meaning.examples,
                "order": meaning.order,
                "timestamp": Timestamp(date: meaning.timestamp)
            ]
        }
        
        let dict: [String: Any] = [
            "wordItself": wordItself,
            "meanings": meaningsData, // New: Multiple meanings
            "partOfSpeech": partOfSpeech,
            "phonetic": phonetic ?? "",
            "tags": tags,
            "difficultyScore": difficultyScore,
            "languageCode": languageCode,
            "isFavorite": isFavorite,
            "timestamp": Timestamp(date: timestamp),
            "updatedAt": Timestamp(date: updatedAt),
            "isSynced": isSynced
        ]
        return dict
    }

    static func fromFirestoreDictionary(_ data: [String: Any], id: String) -> Word? {
        guard let wordItself = data["wordItself"] as? String,
              let partOfSpeech = data["partOfSpeech"] as? String,
              let difficultyScore = data["difficultyScore"] as? Int,
              let languageCode = data["languageCode"] as? String,
              let isFavorite = data["isFavorite"] as? Bool,
              let timestamp = data["timestamp"] as? Timestamp else {
            return nil
        }
        
        // Parse meanings (new format) or fallback to legacy format
        var meanings: [WordMeaning] = []
        
        if let meaningsData = data["meanings"] as? [[String: Any]] {
            // New format: Multiple meanings
            for meaningData in meaningsData {
                guard let meaningId = meaningData["id"] as? String,
                      let definition = meaningData["definition"] as? String,
                      let examples = meaningData["examples"] as? [String],
                      let order = meaningData["order"] as? Int,
                      let meaningTimestamp = meaningData["timestamp"] as? Timestamp else {
                    continue
                }
                
                let meaning = WordMeaning(
                    id: meaningId,
                    definition: definition,
                    examples: examples,
                    order: order,
                    timestamp: meaningTimestamp.dateValue()
                )
                meanings.append(meaning)
            }
        } else if let definition = data["definition"] as? String,
                  let examples = data["examples"] as? [String] {
            // Legacy format: Single definition and examples
            let meaning = WordMeaning(
                definition: definition,
                examples: examples,
                order: 0,
                timestamp: timestamp.dateValue()
            )
            meanings = [meaning]
        }
        
        // Ensure we have at least one meaning
        if meanings.isEmpty {
            return nil
        }
        
        // Tags are optional for shared dictionary words
        let tags = data["tags"] as? [String] ?? []
        
        // Handle optional fields
        let isSynced = data["isSynced"] as? Bool ?? false
        let updatedAt = data["updatedAt"] as? Timestamp ?? timestamp // Fallback to timestamp if updatedAt not present
        
        return Word(
            id: id,
            wordItself: wordItself,
            meanings: meanings,
            partOfSpeech: partOfSpeech,
            phonetic: data["phonetic"] as? String,
            tags: tags,
            difficultyScore: difficultyScore,
            languageCode: languageCode,
            isFavorite: isFavorite,
            timestamp: timestamp.dateValue(),
            updatedAt: updatedAt.dateValue(),
            isSynced: isSynced
        )
    }
}

extension Word {
    init?(from entity: CDWord) {
        guard let id = entity.id?.uuidString,
              let wordItself = entity.wordItself,
              let partOfSpeech = entity.partOfSpeech,
              let timestamp = entity.timestamp else {
            return nil
        }
        
        // Convert CDMeanings to WordMeanings, or fallback to legacy definition
        var meanings: [WordMeaning] = []
        
        if !entity.meaningsArray.isEmpty {
            // Use new meanings structure
            meanings = entity.meaningsArray.map { cdMeaning in
                WordMeaning(
                    id: cdMeaning.id?.uuidString ?? UUID().uuidString,
                    definition: cdMeaning.definition ?? "",
                    examples: cdMeaning.examplesDecoded,
                    order: Int(cdMeaning.order),
                    timestamp: cdMeaning.timestamp ?? timestamp
                )
            }
        } else if let definition = entity.definition, !definition.isEmpty {
            // Fallback to legacy single definition
            let meaning = WordMeaning(
                definition: definition,
                examples: entity.examplesDecoded,
                order: 0,
                timestamp: timestamp
            )
            meanings = [meaning]
        }
        
        // Ensure we have at least one meaning
        guard !meanings.isEmpty else { return nil }
        
        self.id = id
        self.wordItself = wordItself
        self.meanings = meanings
        self.partOfSpeech = partOfSpeech
        self.phonetic = entity.phonetic
        self.tags = entity.tagsArray.map { $0.name ?? "" }
        self.difficultyScore = Int(entity.difficultyScore)
        self.languageCode = entity.languageCode ?? "en" // Default to English if not set
        self.isFavorite = entity.isFavorite
        self.timestamp = timestamp
        self.updatedAt = entity.updatedAt ?? timestamp // Use updatedAt if available, otherwise fallback to timestamp
        self.isSynced = entity.isSynced
    }

    func toCoreDataEntity() -> CDWord {
        let entity = CDWord(context: CoreDataService.shared.context)
        entity.id = UUID(uuidString: id)
        entity.wordItself = wordItself
        entity.partOfSpeech = partOfSpeech
        entity.phonetic = phonetic
        entity.difficultyScore = Int32(difficultyScore)
        entity.languageCode = languageCode
        entity.isFavorite = isFavorite
        entity.timestamp = timestamp
        entity.updatedAt = updatedAt
        entity.isSynced = isSynced
        
        // Create CDMeanings from WordMeanings
        for wordMeaning in meanings {
            do {
                let cdMeaning = try CDMeaning.create(
                    in: CoreDataService.shared.context,
                    definition: wordMeaning.definition,
                    examples: wordMeaning.examples,
                    order: Int32(wordMeaning.order),
                    for: entity
                )
                cdMeaning.id = UUID(uuidString: wordMeaning.id)
                cdMeaning.timestamp = wordMeaning.timestamp
                entity.addToMeanings(cdMeaning)
            } catch {
                // Log error but continue with other meanings
                print("Failed to create CDMeaning: \(error)")
            }
        }
        
        // Set legacy fields for backward compatibility
        entity.definition = definition
        try? entity.updateExamples(examples)
        
        return entity
    }
} 
