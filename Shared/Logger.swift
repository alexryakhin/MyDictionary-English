//
//  Logger.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

func logInfo(_ messages: String...) {
    let concatenatedMessage = messages.joined(separator: " ")
    print("🔹 \(concatenatedMessage)")
}

func logWarning(_ messages: String...) {
    let concatenatedMessage = messages.joined(separator: " ")
    print("⚠️ \(concatenatedMessage)")
}

func logError(_ messages: String...) {
    let concatenatedMessage = messages.joined(separator: " ")
    print("❌ \(concatenatedMessage)")
}
