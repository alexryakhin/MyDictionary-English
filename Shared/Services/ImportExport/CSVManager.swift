//
//  CSVManager.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import UniformTypeIdentifiers
import CoreData
import SwiftUI

final class CSVManager {

    static let shared = CSVManager()

    private let coreDataService: CoreDataService = .shared
    private let authenticationService: AuthenticationService = .shared

    private init() {}

    /// Export Core Data words to a CSV file
    func exportWordsToCSV(wordModels: [CDWord]) -> URL? {
        let subscriptionService = SubscriptionService.shared
        
        // Check export limit for free users
        guard subscriptionService.canExportWords(wordModels.count) else {
            print("❌ [CSVManager] Export limit exceeded: \(wordModels.count) words (limit: \(subscriptionService.getExportLimit()))")
            return nil
        }
        
        let fileName = "MyDictionaryExport.csv"
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var csvString = "word,definition,partOfSpeech,phonetic,is_favorite,timestamp,id,examples,languageCode\n"

        for wordModel in wordModels {
            let date: String = (wordModel.timestamp ?? Date()).csvString
            let word = wordModel.wordItself ?? ""
            let definition = wordModel.definition ?? ""
            let partOfSpeech = wordModel.partOfSpeech ?? ""
            let phonetic = wordModel.phonetic ?? ""
            let isFavorite = wordModel.isFavorite ? "true" : "false"
            let id = wordModel.id?.uuidString ?? ""
            let examples = wordModel.examplesDecoded.joined(separator: ";")
            let languageCode = wordModel.languageCode ?? "en"
            
            let csvRow = [
                word,
                definition,
                partOfSpeech,
                phonetic,
                isFavorite,
                date,
                id,
                examples,
                languageCode
            ]
                .map { "\"\($0)\"" } // Wrap in quotes to handle commas in data
                .joined(separator: ",")

            csvString.append("\(csvRow)\n")
        }

        do {
            try csvString.write(to: filePath, atomically: true, encoding: .utf8)
            return filePath
        } catch {
            logError("Failed to write CSV file: \(error)")
            return nil
        }
    }

    /// Import a CSV file and save words to Core Data
    func importWordsFromCSV(url: URL, currentWordIds: [String]) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw CocoaError(.fileNoSuchFile)
        }
        let fileContents = try String(contentsOf: url)
        let rows = fileContents.components(separatedBy: "\n").dropFirst() // Remove header
        var count = 0

        for row in rows where !row.isEmpty {
            let columns = parseCSVRow(row)

            guard columns.count >= 8, currentWordIds.contains(columns[6]) == false else { continue }

            let newWord = CDWord(context: coreDataService.context)
            newWord.wordItself = columns[0]
            newWord.definition = columns[1]
            newWord.partOfSpeech = columns[2]
            newWord.phonetic = columns[3]
            newWord.isFavorite = (columns[4].lowercased() == "true")
            newWord.timestamp = ISO8601DateFormatter().date(from: columns[5]) ?? Date()
            newWord.id = UUID(uuidString: columns[6])
            newWord.isSynced = false // Mark as unsynced to trigger Firebase sync
            newWord.updatedAt = Date()

            let examplesArray = columns[7].components(separatedBy: ";")
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if examplesArray.isNotEmpty {
                let examplesData = try JSONEncoder().encode(examplesArray)
                newWord.examples = examplesData
            }

            // Handle languageCode (new field, might not exist in old CSV files)
            if columns.count > 8 {
                newWord.languageCode = columns[8]
            }

            count += 1
        }
        if count > 0 {
            try coreDataService.saveContext()
            DispatchQueue.main.async {
                AlertCenter.shared.showAlert(with: .info(title: "Import successful", message: "\(count) words have been imported successfully"))
            }
        } else {
            DispatchQueue.main.async {
                AlertCenter.shared.showAlert(with: .info(title: "No words imported", message: "We couldn't find any new words to import"))
            }
        }
    }

    /// Helper function to properly parse a CSV row
    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false

        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(char)
            }
        }

        result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))

        return result
    }
}
