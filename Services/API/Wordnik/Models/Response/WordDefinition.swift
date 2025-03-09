//
//  WordDefinition.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import Core

struct WordDefinition: Decodable {

    struct ExampleUse: Decodable {
        let text: String
    }

    let partOfSpeech: PartOfSpeech?
    let text: String?
    let exampleUses: [ExampleUse]?
}
