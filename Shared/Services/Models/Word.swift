//
//  Word.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import FirebaseFirestore
import CoreData

struct Word: Codable, Identifiable {
    let id: String
    let wordItself: String
    let definition: String
    let partOfSpeech: String
    let phonetic: String?
    let examples: [String]
    let tags: [String]
    let difficultyLevel: Int
    let languageCode: String
    let isFavorite: Bool
    let timestamp: Date // Created at date
    let updatedAt: Date // Last updated date
    let isSynced: Bool
    let sharedDictionaryId: String?
    
    var isSharedWord: Bool {
        return !(sharedDictionaryId?.isEmpty ?? true)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case wordItself
        case definition
        case partOfSpeech
        case phonetic
        case examples
        case tags
        case difficultyLevel
        case languageCode
        case isFavorite
        case timestamp
        case updatedAt
        case isSynced
        case sharedDictionaryId
    }

    func toFirestoreDictionary() -> [String: Any] {
        let dict: [String: Any] = [
            "wordItself": wordItself,
            "definition": definition,
            "partOfSpeech": partOfSpeech,
            "phonetic": phonetic ?? "",
            "examples": examples,
            "tags": tags,
            "difficultyLevel": difficultyLevel,
            "languageCode": languageCode,
            "isFavorite": isFavorite,
            "timestamp": Timestamp(date: timestamp),
            "updatedAt": Timestamp(date: updatedAt),
            "isSynced": isSynced,
            "sharedDictionaryId": sharedDictionaryId ?? ""
        ]
        print("📝 [Word] toFirestoreDictionary called for word '\(wordItself)', returning: \(dict)")
        return dict
    }

    static func fromFirestoreDictionary(_ data: [String: Any], id: String) -> Word? {
        guard let wordItself = data["wordItself"] as? String,
              let definition = data["definition"] as? String,
              let partOfSpeech = data["partOfSpeech"] as? String,
              let examples = data["examples"] as? [String],
              let tags = data["tags"] as? [String],
              let difficultyLevel = data["difficultyLevel"] as? Int,
              let languageCode = data["languageCode"] as? String,
              let isFavorite = data["isFavorite"] as? Bool,
              let timestamp = data["timestamp"] as? Timestamp else {
            return nil
        }
        
        // Handle optional fields
        let isSynced = data["isSynced"] as? Bool ?? false
        let updatedAt = data["updatedAt"] as? Timestamp ?? timestamp // Fallback to timestamp if updatedAt not present
        let sharedDictionaryId = data["sharedDictionaryId"] as? String
        
        return Word(
            id: id,
            wordItself: wordItself,
            definition: definition,
            partOfSpeech: partOfSpeech,
            phonetic: data["phonetic"] as? String,
            examples: examples,
            tags: tags,
            difficultyLevel: difficultyLevel,
            languageCode: languageCode,
            isFavorite: isFavorite,
            timestamp: timestamp.dateValue(),
            updatedAt: updatedAt.dateValue(),
            isSynced: isSynced,
            sharedDictionaryId: sharedDictionaryId
        )
    }
}

extension Word {
    init?(from entity: CDWord) {
        guard let id = entity.id?.uuidString,
              let wordItself = entity.wordItself,
              let definition = entity.definition,
              let partOfSpeech = entity.partOfSpeech,
              let languageCode = entity.languageCode,
              let timestamp = entity.timestamp else {
            return nil
        }
        self.id = id
        self.wordItself = wordItself
        self.definition = definition
        self.partOfSpeech = partOfSpeech
        self.phonetic = entity.phonetic
        self.examples = entity.examplesDecoded
        self.tags = entity.tagsArray.map { $0.name ?? "" }
        self.difficultyLevel = Int(entity.difficultyLevel)
        self.languageCode = languageCode
        self.isFavorite = entity.isFavorite
        self.timestamp = timestamp
        self.updatedAt = entity.updatedAt ?? timestamp // Use updatedAt if available, otherwise fallback to timestamp
        self.isSynced = entity.isSynced
        self.sharedDictionaryId = entity.sharedDictionaryId
    }

    func toCoreDataEntity() -> CDWord {
        let entity = CDWord(context: CoreDataService.shared.context)
        entity.id = UUID(uuidString: id)
        entity.wordItself = wordItself
        entity.definition = definition
        entity.partOfSpeech = partOfSpeech
        entity.phonetic = phonetic
        try? entity.updateExamples(examples)
        entity.difficultyLevel = Int32(difficultyLevel)
        entity.languageCode = languageCode
        entity.isFavorite = isFavorite
        entity.timestamp = timestamp
        entity.updatedAt = updatedAt
        entity.isSynced = isSynced
        entity.sharedDictionaryId = sharedDictionaryId
        return entity
    }
} 
