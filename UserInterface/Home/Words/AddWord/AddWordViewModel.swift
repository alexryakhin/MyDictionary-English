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
        case selectPartOfSpeech(PartOfSpeech)
        case selectDefinition(WordDefinition)
    }

    enum Output {
        case finish
    }

    var onOutput: ((Output) -> Void)?

    @Published var inputWord = ""
    @Published var descriptionField = ""

    @Published private(set) var status: FetchingStatus = .blank
    @Published private(set) var definitions: [WordDefinition] = []
    @Published private(set) var selectedDefinition: WordDefinition?
    @Published private(set) var pronunciation: String?
    @Published private(set) var partOfSpeech: PartOfSpeech?

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
        case .selectPartOfSpeech(let partOfSpeech):
            self.partOfSpeech = partOfSpeech
        case .selectDefinition(let definition):
            self.selectedDefinition = definition
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
                self.definitions = try await definitions
                self.pronunciation = try await pronunciation
                status = .ready
            } catch {
                errorReceived(error, displayType: .alert, actionText: "Retry") { [weak self] in
                    self?.fetchData()
                }
                status = .error
            }
        }
    }

    private func saveWord() {
        guard inputWord.isCorrect else {
            errorReceived(CoreError.internalError(.inputIsNotAWord), displayType: .alert)
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
                errorReceived(error, displayType: .alert)
            }
        } else {
            errorReceived(CoreError.internalError(.inputCannotBeEmpty), displayType: .alert)
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
                self?.descriptionField = definition.text
                self?.partOfSpeech = definition.partOfSpeech
            }
            .store(in: &cancellables)
    }
}
