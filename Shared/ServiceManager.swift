//
//  ServiceManager.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

final class ServiceManager {
    
    static let shared = ServiceManager()
    
    // MARK: - Services
    
    lazy var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        encoder.dateEncodingStrategy = .formatted(formatter)
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()
    
    lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let formatter = DateFormatter()

            if let date = formatter.convertStringToDate(string: dateString, format: .iso) {
                return date
            }
            if let date = formatter.convertStringToDate(string: dateString, formatString: "yyyy-MM-dd'T'HH:mm:ss'Z'") {
                return date
            }
            if let date = formatter.convertStringToDate(string: dateString, formatString: "yyyy-MM-dd'T'HH:mm:ss") {
                return date
            }
            if let date = formatter.convertStringToDate(string: dateString, formatString: "yyyy-MM-dd'T'HH:mm") {
                return date
            }
            if let date = formatter.convertStringToDate(string: dateString, formatString: "yyyy-MM-dd") {
                return date
            }
            if let date = formatter.convertStringToDate(string: String(dateString.prefix(10)), formatString: "yyyy-MM-dd") {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        return decoder
    }()
    
        lazy var wordnikAPIService: WordnikAPIService = {
        WordnikAPIService(decoder: jsonDecoder)
    }()

    lazy var ttsPlayer: TTSPlayer = {
        TTSPlayer()
    }()

    lazy var coreDataService: CoreDataService = {
        CoreDataService.shared
    }()

    lazy var csvManager: CSVManager = {
        CSVManager(coreDataService: coreDataService)
    }()
    
    lazy var wordsProvider: WordsProvider = {
        WordsProvider(coreDataService: coreDataService)
    }()
    
    lazy var idiomsProvider: IdiomsProvider = {
        IdiomsProvider(coreDataService: coreDataService)
    }()
    
    lazy var tagService: TagService = {
        TagService(coreDataService: coreDataService)
    }()
    
    // MARK: - Factory Methods

    func createAddWordManager() -> AddWordManager {
        AddWordManager(coreDataService: coreDataService)
    }

    func createAddIdiomManager() -> AddIdiomManager {
        AddIdiomManager(coreDataService: coreDataService)
    }
    
    private init() {}
} 
