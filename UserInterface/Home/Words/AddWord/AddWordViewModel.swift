import Core
import CoreUserInterface
import CoreNavigation
import Services
import Shared
import Combine

public final class AddWordViewModel: DefaultPageViewModel {

    enum Input {
        case save
        case fetchData
        case speakInputWord
    }

    enum Output {
        case finish
    }

    var onOutput: ((Output) -> Void)?

    @Published var status: FetchingStatus = .blank
    @Published var inputWord = ""
    @Published var definitions: [WordDefinition] = []
    @Published var selectedDefinition: WordDefinition?
    @Published var descriptionField = ""
    @Published var pronunciation: String?
    @Published var partOfSpeech: PartOfSpeech?

    private let wordnikAPIService: WordnikAPIServiceInterface
    private let addWordManager: AddWordManagerInterface
    private let speechSynthesizer: SpeechSynthesizerInterface
    private var cancellables = Set<AnyCancellable>()

    public init(
        inputWord: String = "",
        wordnikAPIService: WordnikAPIServiceInterface,
        addWordManager: AddWordManagerInterface,
        speechSynthesizer: SpeechSynthesizerInterface
    ) {
        self.inputWord = inputWord
        self.wordnikAPIService = wordnikAPIService
        self.addWordManager = addWordManager
        self.speechSynthesizer = speechSynthesizer

        super.init()
        setupBindings()
        if !inputWord.isEmpty {
            fetchData()
        }
    }

    func handle(_ input: Input) {
        switch input {
        case .save:
            saveWord()
        case .fetchData:
            fetchData()
        case .speakInputWord:
            speechSynthesizer.speak(inputWord)
        }
    }

    private func fetchData() {
        Task { @MainActor in
            status = .loading
            do {
                async let definitions = try wordnikAPIService.getDefinitions(
                    for: inputWord.lowercased(),
                    params: .init()
                )
                async let pronunciation = try wordnikAPIService.getPronunciation(
                    for: inputWord.lowercased(),
                    params: .init()
                )
                self.definitions = try await definitions.filter { $0.text != nil }
                self.pronunciation = try await pronunciation
                status = .ready
            } catch {
                errorReceived(error, displayType: .snack)
                status = .error
            }
        }
    }

    private func saveWord() {
        guard inputWord.isCorrect else {
            errorReceived(CoreError.internalError(.inputIsNotAWord), displayType: .snack)
            return
        }

        if !inputWord.isEmpty, !descriptionField.isEmpty {
            do {
                try addWordManager.addNewWord(
                    word: inputWord.capitalizingFirstLetter(),
                    definition: descriptionField.capitalizingFirstLetter(),
                    partOfSpeech: partOfSpeech?.rawValue ?? "unknown",
                    phonetic: pronunciation,
                    examples: selectedDefinition?.examples ?? []
                )
                onOutput?(.finish)
            } catch {
                errorReceived(error, displayType: .snack)
            }
        } else {
            errorReceived(CoreError.internalError(.inputCannotBeEmpty), displayType: .snack)
        }
    }

    private func speakInputWord() {
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

        $selectedDefinition
            .ifNotNil()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] definition in
                self?.descriptionField = definition.text!
                self?.partOfSpeech = definition.partOfSpeech
            }
            .store(in: &cancellables)
    }
}
