import SwiftUI
import Combine
import CoreData

protocol WordDetailsManagerInterface {

    var wordPublisher: AnyPublisher<Word?, Never> { get }
    var errorPublisher: PassthroughSubject<CoreError, Never> { get }

    func updateWord(_ word: Word)
    /// Removes a given word from the Core Data
    func deleteWord()
}

final class WordDetailsManager: WordDetailsManagerInterface {

    var wordPublisher: AnyPublisher<Word?, Never> {
        _wordPublisher.eraseToAnyPublisher()
    }
    let errorPublisher = PassthroughSubject<CoreError, Never>()

    private let coreDataService: CoreDataServiceInterface

    private let _wordPublisher = CurrentValueSubject<Word?, Never>(nil)
    private var cdWord: CDWord?
    private var cancellables: Set<AnyCancellable> = []

    init(
        wordId: String,
        coreDataService: CoreDataServiceInterface
    ) {
        self.coreDataService = coreDataService
        fetchWord(with: wordId)
    }

    func toggleFavorite() {
        cdWord?.isFavorite.toggle()
        saveContext()
    }

    func updateWord(_ word: Word) {
        cdWord?.isFavorite = word.isFavorite
        cdWord?.phonetic = word.phonetic
        cdWord?.partOfSpeech = word.partOfSpeech.rawValue
        cdWord?.definition = word.definition
        do {
           try cdWord?.updateExamples(word.examples)
        } catch {
            errorPublisher.send(.internalError(.updatingWordExamplesFailed))
        }
        saveContext()
    }

    func deleteWord() {
        guard let cdWord else { return }
        coreDataService.context.delete(cdWord)
        AnalyticsService.shared.logEvent(.wordRemoved)
        saveContext()
    }

    private func fetchWord(with id: String) {
        let fetchRequest: NSFetchRequest<CDWord> = CDWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
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
        } catch {
            errorPublisher.send(.internalError(.removingWordFailed))
        }
    }
}
