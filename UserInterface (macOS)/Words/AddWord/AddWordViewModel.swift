import SwiftUI
import Combine
import Core
import Services
import CoreUserInterface__macOS_
import Shared

final class AddWordViewModel: DefaultPageViewModel {

    @Published var status: FetchingStatus = .blank
    @Published var inputWord = ""
    @Published var definitions: [WordDefinition] = []
    @Published var descriptionField = ""
    @Published var partOfSpeech: PartOfSpeech?
    @Published var showingAlert = false

    private let wordnikAPIService: WordnikAPIServiceInterface
    private let addWordManager: AddWordManagerInterface
    private let ttsPlayer: TTSPlayerInterface
    private var cancellables = Set<AnyCancellable>()

    init(inputWord: String = "") {
        self.inputWord = inputWord
        self.wordnikAPIService = DIContainer.shared.resolver.resolve(WordnikAPIServiceInterface.self)!
        self.addWordManager = DIContainer.shared.resolver.resolve(AddWordManagerInterface.self)!
        self.ttsPlayer = DIContainer.shared.resolver.resolve(TTSPlayerInterface.self)!

        super.init()
        setupBindings()
        if !inputWord.isEmpty {
            fetchData()
        }
    }

    func fetchData() {
        Task { @MainActor in
            status = .loading
            do {
                let definitions = try await wordnikAPIService.getDefinitions(
                    for: inputWord.lowercased(),
                    params: .init()
                )
                self.definitions = definitions
                status = .ready
            } catch {
                print(error)
                status = .error
            }
        }
    }

    func saveWord() {
        if !inputWord.isEmpty, !descriptionField.isEmpty {
            try? addWordManager.addNewWord(
                word: inputWord.capitalizingFirstLetter(),
                definition: descriptionField.capitalizingFirstLetter(),
                partOfSpeech: partOfSpeech?.rawValue ?? "unknown",
                phonetic: nil,
                examples: []
            )
        } else {
            showingAlert = true
        }
    }

    func speakInputWord() {
        Task {
            do {
                try await ttsPlayer.play(inputWord)
            } catch {
                errorReceived(error, displayType: .alert)
            }
        }
    }

    private func setupBindings() {
        $inputWord
            .dropFirst()
            .removeDuplicates()
            .debounce(for: 1, scheduler: RunLoop.main)
            .filter { $0.isNotEmpty && $0.isCorrect }
            .sink { [weak self] _ in
                guard self?.status != .loading else { return }
                self?.fetchData()
            }
            .store(in: &cancellables)
    }
}
