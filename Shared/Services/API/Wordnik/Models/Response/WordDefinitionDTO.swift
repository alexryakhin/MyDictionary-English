//
//  WordDefinitionDTO.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

struct WordDefinitionDTO: Decodable {

    struct ExampleUse: Decodable {
        let text: String
    }

    let partOfSpeech: PartOfSpeechDTO?
    let text: String?
    let exampleUses: [ExampleUse]?
}
