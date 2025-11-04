//
//  WordCollectionDetailsViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 1/27/25.
//

import Foundation
import Combine

@MainActor
final class WordCollectionDetailsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var collection: WordCollection
    @Published var isTranslating = false
    @Published var translationError: Error?
    
    // MARK: - Private Properties
    
    private let translationService: TranslationService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    private var localeLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }
    
    // MARK: - Initialization
    
    init(collection: WordCollection, translationService: TranslationService = GoogleTranslateService.shared) {
        self.collection = collection
        self.translationService = translationService
    }
    
    // MARK: - Public Methods
    
    /// Returns the translated collection with updated definitions
    var translatedCollection: WordCollection {
        return collection
    }
    
    /// Manually triggers translation of definitions
    func translateDefinitions() async {
        isTranslating = true
        translationError = nil
        
        do {
            await performTranslation()
        } catch {
            translationError = error
            print("❌ [WordCollectionDetailsViewModel] Translation failed: \(error)")
        }
        
        isTranslating = false
    }
    
    // MARK: - Private Methods
    
    private func performTranslation() async {
        // Create a copy of the collection with translated definitions
        var translatedWords: [WordCollectionItem] = []
        
        // Use TaskGroup for parallel translation
        await withTaskGroup(of: (Int, WordCollectionItem).self) { group in
            for (index, word) in collection.words.enumerated() {
                group.addTask {
                    do {
                        let translatedDefinition = try await self.translationService.translateDefinition(
                            word.definition,
                            from: self.collection.languageCode,
                            to: self.localeLanguageCode
                        )
                        
                        let translatedWord = WordCollectionItem(
                            id: word.id,
                            text: word.text,
                            phonetics: word.phonetics,
                            partOfSpeech: word.partOfSpeech,
                            definition: translatedDefinition,
                            examples: word.examples
                        )
                        
                        return (index, translatedWord)
                    } catch {
                        // Fallback to original word if translation fails
                        print("⚠️ [WordCollectionDetailsViewModel] Failed to translate definition for '\(word.text)': \(error)")
                        return (index, word)
                    }
                }
            }
            
            // Collect results and maintain original order
            var orderedResults: [(Int, WordCollectionItem)] = []
            for await (index, translatedWord) in group {
                orderedResults.append((index, translatedWord))
            }
            
            // Sort by the original index to maintain order
            orderedResults.sort { $0.0 < $1.0 }
            
            // Extract the translated words in correct order
            translatedWords = orderedResults.map { $0.1 }
        }
        
        // Update the collection with translated definitions
        let translatedCollection = WordCollection(
            id: collection.id,
            title: collection.title,
            words: translatedWords,
            level: collection.level,
            tagValue: collection.tagValue,
            languageCode: collection.languageCode,
            description: collection.description,
            imageUrl: collection.imageUrl,
            localImageName: collection.localImageName,
            isPremium: collection.isPremium,
            isFeatured: collection.isFeatured
        )
        
        self.collection = translatedCollection
    }
}
