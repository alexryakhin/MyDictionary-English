//
//  SpeechifyConfig.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

enum SpeechifyConfig {
    static let maxCharactersPerRequest = 400
    static let maxRequestsPerMinute = 60

    static func validateText(_ text: String) -> Bool {
        return text.isNotEmpty && text.count <= maxCharactersPerRequest
    }
}
