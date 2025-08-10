//
//  SharedWord.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/1/25.
//

import Foundation
import FirebaseFirestore

struct SharedWord: Codable, Hashable {
    let id: String
    let wordItself: String
    let definition: String
    let partOfSpeech: String
    let phonetic: String?
    let examples: [String]
    let languageCode: String
    let timestamp: Date
    let updatedAt: Date
    let sharedDictionaryId: String?
    
    // MARK: - Initialization
    
    init(
        id: String,
        wordItself: String,
        definition: String,
        partOfSpeech: String,
        phonetic: String?,
        examples: [String],
        languageCode: String,
        timestamp: Date = Date(),
        updatedAt: Date = Date(),
        sharedDictionaryId: String? = nil
    ) {
        self.id = id
        self.wordItself = wordItself
        self.definition = definition
        self.partOfSpeech = partOfSpeech
        self.phonetic = phonetic
        self.examples = examples
        self.languageCode = languageCode
        self.timestamp = timestamp
        self.updatedAt = updatedAt
        self.sharedDictionaryId = sharedDictionaryId
    }
    
    // MARK: - Conversion from Word
    
    init(from word: Word) {
        self.id = word.id
        self.wordItself = word.wordItself
        self.definition = word.definition
        self.partOfSpeech = word.partOfSpeech
        self.phonetic = word.phonetic
        self.examples = word.examples
        self.languageCode = word.languageCode
        self.timestamp = word.timestamp
        self.updatedAt = word.updatedAt
        self.sharedDictionaryId = word.sharedDictionaryId
    }
    
    // MARK: - Firestore Conversion
    
    func toFirestoreDictionary() -> [String: Any] {
        let dict: [String: Any] = [
            "wordItself": wordItself,
            "definition": definition,
            "partOfSpeech": partOfSpeech,
            "phonetic": phonetic ?? "",
            "examples": examples,
            "languageCode": languageCode,
            "timestamp": Timestamp(date: timestamp),
            "updatedAt": Timestamp(date: updatedAt),
            "sharedDictionaryId": sharedDictionaryId ?? ""
        ]
        print("📝 [SharedWord] toFirestoreDictionary called for word '\(wordItself)', returning: \(dict)")
        return dict
    }
    
    static func fromFirestoreDictionary(_ data: [String: Any], id: String) -> SharedWord? {
        guard let wordItself = data["wordItself"] as? String,
              let definition = data["definition"] as? String,
              let partOfSpeech = data["partOfSpeech"] as? String,
              let examples = data["examples"] as? [String],
              let languageCode = data["languageCode"] as? String,
              let timestamp = data["timestamp"] as? Timestamp else {
            return nil
        }
        
        // Handle optional fields
        let updatedAt = data["updatedAt"] as? Timestamp ?? timestamp
        let sharedDictionaryId = data["sharedDictionaryId"] as? String
        
        return SharedWord(
            id: id,
            wordItself: wordItself,
            definition: definition,
            partOfSpeech: partOfSpeech,
            phonetic: data["phonetic"] as? String,
            examples: examples,
            languageCode: languageCode,
            timestamp: timestamp.dateValue(),
            updatedAt: updatedAt.dateValue(),
            sharedDictionaryId: sharedDictionaryId
        )
    }
    
    // MARK: - Core Data Conversion
    
    func toCoreDataEntity() -> CDWord {
        let entity = CDWord(context: CoreDataService.shared.context)
        entity.id = UUID(uuidString: id)
        entity.wordItself = wordItself
        entity.definition = definition
        entity.partOfSpeech = partOfSpeech
        entity.phonetic = phonetic
        try? entity.updateExamples(examples)
        entity.difficultyLevel = 0 // Default for shared words
        entity.languageCode = languageCode
        entity.isFavorite = false // Default for shared words
        entity.timestamp = timestamp
        entity.updatedAt = updatedAt
        entity.isSynced = true
        entity.sharedDictionaryId = sharedDictionaryId
        // Don't add tags for shared words
        return entity
    }
}
