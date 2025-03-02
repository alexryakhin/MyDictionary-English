import SwiftUI
import Combine
import CoreData
import Swinject
import SwinjectAutoregistration

protocol WordsProviderInterface {
    var wordsPublisher: AnyPublisher<[Word], Never> { get }
    var wordsErrorPublisher: AnyPublisher<CoreError, Never> { get }

    /// Fetches latest data from Core Data
    func fetchWords()
}

final class WordsProvider: WordsProviderInterface {

    var wordsPublisher: AnyPublisher<[Word], Never> {
        _wordsPublisher.eraseToAnyPublisher()
    }

    var wordsErrorPublisher: AnyPublisher<CoreError, Never> {
        _wordsErrorPublisher.eraseToAnyPublisher()
    }

    private let _wordsPublisher = CurrentValueSubject<[Word], Never>([])
    private let _wordsErrorPublisher = PassthroughSubject<CoreError, Never>()
    private let coreDataContainer = CoreDataContainer.shared
    private var cancellable = Set<AnyCancellable>()

    init() {
        setupBindings()
        fetchWords()
    }

    /// Fetches latest data from Core Data
    func fetchWords() {
        let request = NSFetchRequest<Word>(entityName: "Word")
        do {
            let words = try coreDataContainer.viewContext.fetch(request)
            _wordsPublisher.send(words)
        } catch {
            _wordsErrorPublisher.send(.storageError(.readFailed))
        }
    }

    private func setupBindings() {
        // every time core data gets updated, call fetchWords()
        NotificationCenter.default.mergeChangesObjectIDsPublisher
            .combineLatest(NotificationCenter.default.coreDataDidSavePublisher)
            .sink { [weak self] _ in
                self?.fetchWords()
            }
            .store(in: &cancellable)
    }
}
