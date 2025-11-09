//
//  Logger.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

func logSuccess(_ messages: String...) {
    let concatenatedMessage = messages.joined(separator: " ")
    debugPrint("LOGGER ✅ \(concatenatedMessage)")
}

func logInfo(_ messages: String...) {
    let concatenatedMessage = messages.joined(separator: " ")
    debugPrint("LOGGER ℹ️ \(concatenatedMessage)")
}

func logWarning(_ messages: String...) {
    let concatenatedMessage = messages.joined(separator: " ")
    debugPrint("LOGGER ⚠️ \(concatenatedMessage)")
}

func logError(_ messages: String...) {
    let concatenatedMessage = messages.joined(separator: " ")
    debugPrint("LOGGER ❌ \(concatenatedMessage)")
}
