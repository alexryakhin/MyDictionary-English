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
import Core
import Shared

public protocol CSVManagerInterface {

    /// Export Core Data words to a CSV file
    func exportWordsToCSV(wordModels: [Word]) -> URL?

    /// Import a CSV file and save words to Core Data
    func importWordsFromCSV(url: URL, currentWordIds: [String]) throws
}

public final class CSVManager: CSVManagerInterface {

    private let coreDataService: CoreDataServiceInterface

    public init(coreDataService: CoreDataServiceInterface) {
        self.coreDataService = coreDataService
    }

    /// Export Core Data words to a CSV file
    public func exportWordsToCSV(wordModels: [Word]) -> URL? {
        let fileName = "MyDictionaryExport.csv"
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var csvString = "word,definition,partOfSpeech,phonetic,is_favorite,timestamp,id,examples\n"

        for wordModel in wordModels {
            let date: String = wordModel.timestamp.csvString
            let id: String = wordModel.id.uuidString
            let csvRow = [
                wordModel.word,
                wordModel.definition,
                wordModel.partOfSpeech.rawValue,
                wordModel.phonetic ?? "",
                wordModel.isFavorite ? "true" : "false",
                date,
                id,
                wordModel.examples.joined(separator: ";")
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
    public func importWordsFromCSV(url: URL, currentWordIds: [String]) throws {
        let fileContents = try String(contentsOf: url)
        let rows = fileContents.components(separatedBy: "\n").dropFirst() // Remove header

        for row in rows where !row.isEmpty {
            let columns = parseCSVRow(row)

            guard columns.count == 8, currentWordIds.contains(columns[6]) == false else { continue }

            let newWord = CDWord(context: coreDataService.context)
            newWord.wordItself = columns[0]
            newWord.definition = columns[1]
            newWord.partOfSpeech = columns[2]
            newWord.phonetic = columns[3]
            newWord.isFavorite = (columns[4].lowercased() == "true")
            newWord.timestamp = ISO8601DateFormatter().date(from: columns[5]) ?? Date()
            newWord.id = UUID(uuidString: columns[6])

            let examplesArray = columns[7].components(separatedBy: ";")
            let examplesData = try JSONEncoder().encode(examplesArray)
            newWord.examples = examplesData
        }

        try coreDataService.saveContext()
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
