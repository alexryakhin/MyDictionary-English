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

    
    // Collaborator information
    let addedByEmail: String
    let addedByDisplayName: String?
    let addedAt: Date
    
    // Collaborative features
    let likes: [String: Bool] // userEmail -> isLiked
    let difficulties: [String: Int] // userEmail -> difficultyLevel (0-3)
    
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

        addedByEmail: String,
        addedByDisplayName: String? = nil,
        addedAt: Date = Date(),
        likes: [String: Bool] = [:],
        difficulties: [String: Int] = [:]
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

        self.addedByEmail = addedByEmail
        self.addedByDisplayName = addedByDisplayName
        self.addedAt = addedAt
        self.likes = likes
        self.difficulties = difficulties
    }
    
    // MARK: - Conversion from Word
    
    init(from word: Word, addedByEmail: String, addedByDisplayName: String? = nil) {
        self.id = word.id
        self.wordItself = word.wordItself
        self.definition = word.definition
        self.partOfSpeech = word.partOfSpeech
        self.phonetic = word.phonetic
        self.examples = word.examples
        self.languageCode = word.languageCode
        self.timestamp = word.timestamp
        self.updatedAt = word.updatedAt

        self.addedByEmail = addedByEmail
        self.addedByDisplayName = addedByDisplayName
        self.addedAt = Date()
        self.likes = [:]
        self.difficulties = [:]
    }

    var shouldShowLanguageLabel: Bool {
        return languageCode.nilIfEmpty != nil && languageCode != "en"
    }

    var languageDisplayName: String {
        guard let language = Locale.current.localizedString(forLanguageCode: languageCode) else { return "Unknown" }
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
        case 0: return "New"
        case 1: return "In Progress"
        case 2: return "Needs Review"
        case 3: return "Mastered"
        default: return "New"
        }
    }

    // MARK: - Firestore Conversion
    
    func toFirestoreDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "wordItself": wordItself,
            "definition": definition,
            "partOfSpeech": partOfSpeech,
            "phonetic": phonetic ?? "",
            "examples": examples,
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
        
        print("📝 [SharedWord] toFirestoreDictionary called for word '\(wordItself)', returning: \(dict)")
        return dict
    }
    
    static func fromFirestoreDictionary(_ data: [String: Any], id: String) -> SharedWord? {
        guard let wordItself = data["wordItself"] as? String,
              let definition = data["definition"] as? String,
              let partOfSpeech = data["partOfSpeech"] as? String,
              let examples = data["examples"] as? [String],
              let languageCode = data["languageCode"] as? String,
              let timestamp = data["timestamp"] as? Timestamp,
              let addedByEmail = data["addedByEmail"] as? String,
              let addedAt = data["addedAt"] as? Timestamp else {
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
            definition: definition,
            partOfSpeech: partOfSpeech,
            phonetic: data["phonetic"] as? String,
            examples: examples,
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
