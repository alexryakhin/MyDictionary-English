import SwiftUI
import Combine

final class AddWordViewModel: ViewModel {

    @Published var status: FetchingStatus = .blank
    @Published var inputWord = ""
    @Published var definitions: [WordDefinition] = []
    @Published var descriptionField = ""
    @Published var partOfSpeech: PartOfSpeech?
    @Published var showingAlert = false

    private let wordnikApiService: WordnikApiServiceInterface
    private let wordsManager: WordsManagerInterface
    private let speechSynthesizer = SpeechSynthesizer.shared
    private var cancellables = Set<AnyCancellable>()

    init(
        inputWord: String = "",
        wordnikApiService: WordnikApiServiceInterface,
        wordsManager: WordsManagerInterface
    ) {
        self.inputWord = inputWord
        self.wordnikApiService = wordnikApiService
        self.wordsManager = wordsManager

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
                let definitions = try await wordnikApiService.getDefinitions(
                    for: inputWord.lowercased(),
                    params: .init()
                )
                self.definitions = definitions.filter { $0.text != nil }
                status = .ready
            } catch {
                print(error)
                status = .error
            }
        }
    }

    func saveWord() {
        if !inputWord.isEmpty, !descriptionField.isEmpty {
            wordsManager.addNewWord(
                word: inputWord.capitalizingFirstLetter(),
                definition: descriptionField.capitalizingFirstLetter(),
                partOfSpeech: partOfSpeech?.rawValue ?? "unknown",
                phonetic: nil
            )
            saveContext()
        } else {
            showingAlert = true
        }
    }

    func speakInputWord() {
        speechSynthesizer.speak(inputWord)
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

    private func saveContext() {
        do {
            try wordsManager.saveContext()
        } catch {
            handleError(error)
        }
    }
}
