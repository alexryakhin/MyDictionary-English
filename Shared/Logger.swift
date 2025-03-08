//
//  Logger.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

public func logInfo(_ messages: String...) {
    let concatenatedMessage = messages.joined(separator: " ")
    print("🔹 \(concatenatedMessage)")
}

public func logWarning(_ messages: String...) {
    let concatenatedMessage = messages.joined(separator: " ")
    print("⚠️ \(concatenatedMessage)")
}

public func logError(_ messages: String...) {
    let concatenatedMessage = messages.joined(separator: " ")
    print("❌ \(concatenatedMessage)")
}
