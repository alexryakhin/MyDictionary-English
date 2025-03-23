import SwiftUI
import Combine
import CoreData
import Core

public protocol WordDetailsManagerInterface {

    var wordPublisher: AnyPublisher<Word?, Never> { get }
    var errorPublisher: PassthroughSubject<CoreError, Never> { get }

    func toggleFavorite()
    func updateDefinition(_ definition: String)
    func updatePartOfSpeech(_ partOfSpeech: String)
    func addExample(_ example: String)
    func removeExample(atOffsets offsets: IndexSet)
    /// Removes a given word from the Core Data
    func deleteWord()
}

public final class WordDetailsManager: WordDetailsManagerInterface {

    public var wordPublisher: AnyPublisher<Word?, Never> {
        _wordPublisher.eraseToAnyPublisher()
    }
    public let errorPublisher = PassthroughSubject<CoreError, Never>()

    private let wordId: String
    private let coreDataService: CoreDataServiceInterface

    private let _wordPublisher = CurrentValueSubject<Word?, Never>(nil)
    private var cdWord: CDWord?
    private var cancellables: Set<AnyCancellable> = []

    public init(
        wordId: String,
        coreDataService: CoreDataServiceInterface
    ) {
        self.wordId = wordId
        self.coreDataService = coreDataService
        fetchWord()
    }

    public func toggleFavorite() {
        cdWord?.isFavorite.toggle()
        saveContext()
    }

    public func updateDefinition(_ definition: String) {
        cdWord?.definition = definition
        saveContext()
    }

    public func updatePartOfSpeech(_ partOfSpeech: String) {
        cdWord?.partOfSpeech = partOfSpeech
        saveContext()
    }

    public func addExample(_ example: String) {
        do {
            try cdWord?.addExample(example)
        } catch {
            errorPublisher.send(.internalError(.savingWordExampleFailed))
        }
        saveContext()
    }

    public func removeExample(atOffsets offsets: IndexSet) {
        do {
            try cdWord?.removeExample(atOffsets: offsets)
        } catch {
            errorPublisher.send(.internalError(.removingWordExampleFailed))
        }
        saveContext()
    }

    public func deleteWord() {
        guard let cdWord else { return }
        coreDataService.context.delete(cdWord)
        AnalyticsService.shared.logEvent(.wordRemoved(word: cdWord.wordItself.orEmpty))
        saveContext()
    }

    private func fetchWord() {
        let fetchRequest: NSFetchRequest<CDWord> = CDWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", wordId)
        do {
            if let cdWord: CDWord = try coreDataService.context.fetch(fetchRequest).first {
                self.cdWord = cdWord
                _wordPublisher.send(cdWord.coreModel)
            }
        } catch {
            errorPublisher.send(.storageError(.readFailed))
        }
    }

    private func saveContext() {
        do {
            try coreDataService.saveContext()
            _wordPublisher.send(cdWord?.coreModel)
        } catch {
            errorPublisher.send(.internalError(.removingWordFailed))
        }
    }
}
