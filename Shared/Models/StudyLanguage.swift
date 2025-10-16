//
//  StudyLanguage.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

struct StudyLanguage: Codable, Identifiable, Hashable {
    let id: UUID
    let language: InputLanguage
    let proficiencyLevel: CEFRLevel
    
    init(id: UUID = UUID(), language: InputLanguage, proficiencyLevel: CEFRLevel) {
        self.id = id
        self.language = language
        self.proficiencyLevel = proficiencyLevel
    }
    
    var displayName: String {
        return "\(language.displayName) (\(proficiencyLevel.rawValue))"
    }
}

