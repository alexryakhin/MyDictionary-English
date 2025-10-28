import SwiftUI
import Combine
import CoreData

final class WordsProvider: ObservableObject {

    static let shared = WordsProvider()

    @Published var words: [CDWord] = []
    @Published var expressions: [CDWord] = []

    private let coreDataService: CoreDataService = .shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupBindings()
        try? fetchWords()
    }

    /// Fetches latest data from Core Data
    func fetchWords() throws {
        let request = CDWord.fetchRequest()
        let allWords = try coreDataService.context.fetch(request)

        // Separate regular words from expressions
        self.words = allWords.filter { $0.isRegularWord }
        self.expressions = allWords.filter { $0.isExpression }
    }
    
    /// Fetches only regular words (excluding expressions)
    func fetchRegularWords() -> [CDWord] {
        let request = CDWord.fetchRequest()
        request.predicate = NSPredicate(format: "partOfSpeech != %@ AND partOfSpeech != %@", "idiom", "phrase")
        return (try? coreDataService.context.fetch(request)) ?? []
    }
    
    /// Fetches only expressions (idioms and phrases)
    func fetchExpressions() -> [CDWord] {
        let request = CDWord.fetchRequest()
        request.predicate = NSPredicate(format: "partOfSpeech == %@ OR partOfSpeech == %@", "idiom", "phrase")
        return (try? coreDataService.context.fetch(request)) ?? []
    }
    
    /// Fetches favorite words (both regular words and expressions)
    func fetchFavoriteWords() -> [CDWord] {
        let request = CDWord.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == YES")
        return (try? coreDataService.context.fetch(request)) ?? []
    }

    /// Removes a given word from the Core Data
    func delete(with id: String) throws {
        let fetchRequest = CDWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        if let object = try coreDataService.context.fetch(fetchRequest).first {
            // Clean up associated image file before deleting the word
            if let imageLocalPath = object.imageLocalPath, !imageLocalPath.isEmpty {
                do {
                    try PexelsService.shared.deleteImage(at: imageLocalPath)
                    print("🗑️ [WordsProvider] Deleted image file: \(imageLocalPath)")
                } catch {
                    print("⚠️ [WordsProvider] Failed to delete image file: \(error.localizedDescription)")
                    // Continue with word deletion even if image cleanup fails
                }
            }
            
            coreDataService.context.delete(object)
            #if os(macOS)
            SideBarManager.shared.selectedWord = nil
            #endif
            try coreDataService.saveContext()
            // Manually refresh the words list after deletion
            try fetchWords()
        } else {
            throw CoreError.internalError(.removingWordFailed)
        }
    }
    
    /// Gets all words for a specific language
    func getWords(for languageCode: String) -> [CDWord] {
        let request = CDWord.fetchRequest()
        request.predicate = NSPredicate(format: "languageCode == %@", languageCode)
        return (try? coreDataService.context.fetch(request)) ?? []
    }
    
    /// Gets words by part of speech
    func getWords(byPartOfSpeech partOfSpeech: PartOfSpeech) -> [CDWord] {
        let request = CDWord.fetchRequest()
        request.predicate = NSPredicate(format: "partOfSpeech == %@", partOfSpeech.rawValue)
        return (try? coreDataService.context.fetch(request)) ?? []
    }
    
    /// Searches words by text
    func searchWords(text: String) -> [CDWord] {
        let request = CDWord.fetchRequest()
        request.predicate = NSPredicate(format: "wordItself CONTAINS[cd] %@", text)
        return (try? coreDataService.context.fetch(request)) ?? []
    }
    
    /// Deletes multiple words by their IDs
    func deleteWords(with ids: [String]) throws {
        guard !ids.isEmpty else { return }
        
        let fetchRequest = CDWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id IN %@", ids)
        let objectsToDelete = try coreDataService.context.fetch(fetchRequest)
        
        // Clean up associated image files before deleting words
        for object in objectsToDelete {
            if let imageLocalPath = object.imageLocalPath, !imageLocalPath.isEmpty {
                do {
                    try PexelsService.shared.deleteImage(at: imageLocalPath)
                    print("🗑️ [WordsProvider] Deleted image file: \(imageLocalPath)")
                } catch {
                    print("⚠️ [WordsProvider] Failed to delete image file: \(error.localizedDescription)")
                    // Continue with word deletion even if image cleanup fails
                }
            }
        }
        
        // Delete all objects
        for object in objectsToDelete {
            coreDataService.context.delete(object)
        }
        
        #if os(macOS)
        SideBarManager.shared.selectedWord = nil
        #endif
        
        try coreDataService.saveContext()
        // Manually refresh the words list after deletion
        try fetchWords()
    }
    
    /// Deletes all words from the dictionary
    func deleteAllWords() throws {
        let fetchRequest = CDWord.fetchRequest()
        let allWords = try coreDataService.context.fetch(fetchRequest)
        
        // Clean up associated image files before deleting words
        for word in allWords {
            if let imageLocalPath = word.imageLocalPath, !imageLocalPath.isEmpty {
                do {
                    try PexelsService.shared.deleteImage(at: imageLocalPath)
                    print("🗑️ [WordsProvider] Deleted image file: \(imageLocalPath)")
                } catch {
                    print("⚠️ [WordsProvider] Failed to delete image file: \(error.localizedDescription)")
                    // Continue with word deletion even if image cleanup fails
                }
            }
        }
        
        // Delete all words
        for word in allWords {
            coreDataService.context.delete(word)
        }
        
        #if os(macOS)
        SideBarManager.shared.selectedWord = nil
        #endif
        
        try coreDataService.saveContext()
        // Manually refresh the words list after deletion
        try fetchWords()
    }

    private func setupBindings() {
        coreDataService.dataUpdatedPublisher
            .sink { [weak self] _ in
                try? self?.fetchWords()
            }
            .store(in: &cancellables)
    }
}
