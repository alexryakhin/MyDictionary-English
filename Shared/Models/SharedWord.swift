//
//  SharedWord.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/1/25.
//

import Foundation
import FirebaseFirestore

struct SharedWordMeaning: Codable, Hashable, Identifiable {
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

struct SharedWord: Codable, Hashable {
    let id: String
    let wordItself: String
    var meanings: [SharedWordMeaning] // New: Multiple meanings support
    var partOfSpeech: String
    var phonetic: String?
    var notes: String?
    var languageCode: String
    let timestamp: Date
    let updatedAt: Date
    var imageUrl: String? // Pexels image URL
    var imageLocalPath: String? // Local path to saved image

    // Collaborator information
    let addedByEmail: String
    let addedByDisplayName: String?
    let addedAt: Date
    
    // Collaborative features
    var likes: [String: Bool] // userEmail -> isLiked
    var difficulties: [String: Int] // userEmail -> difficultyScore

    // MARK: - Initialization
    
    init(
        id: String,
        wordItself: String,
        meanings: [SharedWordMeaning],
        partOfSpeech: String,
        phonetic: String?,
        notes: String?,
        languageCode: String,
        timestamp: Date = Date(),
        updatedAt: Date = Date(),
        addedByEmail: String,
        addedByDisplayName: String? = nil,
        addedAt: Date = Date(),
        likes: [String: Bool] = [:],
        difficulties: [String: Int] = [:],
        imageUrl: String? = nil,
        imageLocalPath: String? = nil
    ) {
        self.id = id
        self.wordItself = wordItself
        self.meanings = meanings
        self.partOfSpeech = partOfSpeech
        self.phonetic = phonetic
        self.notes = notes
        self.languageCode = languageCode
        self.timestamp = timestamp
        self.updatedAt = updatedAt
        self.imageUrl = imageUrl
        self.imageLocalPath = imageLocalPath

        self.addedByEmail = addedByEmail
        self.addedByDisplayName = addedByDisplayName
        self.addedAt = addedAt
        self.likes = likes
        self.difficulties = difficulties
    }
    
    // Convenience initializer for single meaning (backward compatibility)
    init(
        id: String,
        wordItself: String,
        definition: String,
        partOfSpeech: String,
        phonetic: String?,
        notes: String?,
        examples: [String],
        languageCode: String,
        timestamp: Date = Date(),
        updatedAt: Date = Date(),
        addedByEmail: String,
        addedByDisplayName: String? = nil,
        addedAt: Date = Date(),
        likes: [String: Bool] = [:],
        difficulties: [String: Int] = [:]
    ) {
        let meaning = SharedWordMeaning(definition: definition, examples: examples, order: 0)
        self.init(
            id: id,
            wordItself: wordItself,
            meanings: [meaning],
            partOfSpeech: partOfSpeech,
            phonetic: phonetic,
            notes: notes,
            languageCode: languageCode,
            timestamp: timestamp,
            updatedAt: updatedAt,
            addedByEmail: addedByEmail,
            addedByDisplayName: addedByDisplayName,
            addedAt: addedAt,
            likes: likes,
            difficulties: difficulties
        )
    }
    
    // MARK: - Conversion from Word
    
    init(from word: Word, addedByEmail: String, addedByDisplayName: String? = nil) {
        // Convert single Word to SharedWord with single meaning
        let meaning = SharedWordMeaning(
            definition: word.definition,
            examples: word.examples,
            order: 0
        )
        
        self.id = word.id
        self.wordItself = word.wordItself
        self.meanings = [meaning]
        self.partOfSpeech = word.partOfSpeech
        self.phonetic = word.phonetic
        self.notes = word.notes
        self.languageCode = word.languageCode
        self.timestamp = word.timestamp
        self.updatedAt = word.updatedAt

        self.addedByEmail = addedByEmail
        self.addedByDisplayName = addedByDisplayName
        self.addedAt = Date()
        self.likes = [:]
        self.difficulties = [:]
    }
    
    // MARK: - Computed Properties for Backward Compatibility
    
    /// Primary meaning (first meaning)
    var primaryMeaning: SharedWordMeaning? {
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
    var sortedMeanings: [SharedWordMeaning] {
        return meanings.sorted { $0.order < $1.order }
    }

    var shouldShowLanguageLabel: Bool {
        return languageCode.nilIfEmpty != nil && languageCode != "en"
    }

    var languageDisplayName: String {
        guard let language = Locale.current.localizedString(forLanguageCode: languageCode) else { return Loc.Errors.unknown }
        return language.capitalized
    }
    
    var addedByDisplayText: String {
        let name = addedByDisplayName ?? addedByEmail
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return "Added by \(name) on \(dateFormatter.string(from: addedAt))"
    }
    
    var addedByShortText: String {
        return addedByDisplayName ?? addedByEmail
    }
    
    // MARK: - Collaborative Features
    
    var likeCount: Int {
        return likes.values.filter { $0 }.count
    }
    
    var averageDifficulty: Double {
        guard !difficulties.isEmpty else { return 0.0 }
        let sum = difficulties.values.reduce(0, +)
        return Double(sum) / Double(difficulties.count)
    }
    
    func isLikedBy(_ userEmail: String) -> Bool {
        return likes[userEmail] ?? false
    }
    
    func getDifficultyFor(_ userEmail: String) -> Int {
        return difficulties[userEmail] ?? 0
    }
    
    func getDifficultyDisplayName(for userEmail: String) -> String {
        let difficulty = getDifficultyFor(userEmail)
        switch difficulty {
        case 0: return Loc.Words.Difficulty.new
        case 1: return Loc.Words.Difficulty.inProgress
        case 2: return Loc.Words.Difficulty.needsReview
        case 3: return Loc.Words.Difficulty.mastered
        default: return Loc.Words.Difficulty.new
        }
    }

    // MARK: - Firestore Conversion
    
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
        
        var dict: [String: Any] = [
            "wordItself": wordItself,
            "meanings": meaningsData, // New: Multiple meanings
            "partOfSpeech": partOfSpeech,
            "phonetic": phonetic ?? "",
            "notes": notes ?? "",
            "languageCode": languageCode,
            "timestamp": Timestamp(date: timestamp),
            "updatedAt": Timestamp(date: updatedAt),
            "addedByEmail": addedByEmail,
            "addedAt": Timestamp(date: addedAt),
            "likes": likes,
            "difficulties": difficulties
        ]
        
        if let addedByDisplayName = addedByDisplayName {
            dict["addedByDisplayName"] = addedByDisplayName
        }
        
        return dict
    }
    
    static func fromFirestoreDictionary(_ data: [String: Any], id: String) -> SharedWord? {
        guard let wordItself = data["wordItself"] as? String,
              let partOfSpeech = data["partOfSpeech"] as? String,
              let languageCode = data["languageCode"] as? String,
              let timestamp = data["timestamp"] as? Timestamp,
              let addedByEmail = data["addedByEmail"] as? String,
              let addedAt = data["addedAt"] as? Timestamp else {
            return nil
        }
        
        // Parse meanings (new format) or fallback to legacy format
        var meanings: [SharedWordMeaning] = []
        
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
                
                let meaning = SharedWordMeaning(
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
            let meaning = SharedWordMeaning(
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
        
        // Handle optional fields
        let updatedAt = data["updatedAt"] as? Timestamp ?? timestamp
        let addedByDisplayName = data["addedByDisplayName"] as? String
        
        // Handle collaborative features (with defaults for backward compatibility)
        let likes = data["likes"] as? [String: Bool] ?? [:]
        let difficulties = data["difficulties"] as? [String: Int] ?? [:]
        
        return SharedWord(
            id: id,
            wordItself: wordItself,
            meanings: meanings,
            partOfSpeech: partOfSpeech,
            phonetic: data["phonetic"] as? String,
            notes: data["notes"] as? String,
            languageCode: languageCode,
            timestamp: timestamp.dateValue(),
            updatedAt: updatedAt.dateValue(),
            addedByEmail: addedByEmail,
            addedByDisplayName: addedByDisplayName,
            addedAt: addedAt.dateValue(),
            likes: likes,
            difficulties: difficulties
        )
    }
}
