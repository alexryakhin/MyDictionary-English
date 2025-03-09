import Core
import CoreUserInterface
import CoreNavigation
import Services
import Shared
import Combine

public final class WordDetailsViewModel: DefaultPageViewModel {

    enum Input {
        case speak(String?)
        case toggleFavorite
        case updatePartOfSpeech(String)
        case toggleShowAddExample
        case addExample
        case removeExample(IndexSet)
        case deleteWord
    }

    enum Output {
        case finish
    }

    var onOutput: ((Output) -> Void)?

    @Published var definitionTextFieldStr = ""
    @Published var exampleTextFieldStr = ""

    @Published private(set) var word: Word
    @Published private(set) var isShowAddExample = false

    // MARK: - Private Properties

    private let wordDetailsManager: WordDetailsManagerInterface
    private let speechSynthesizer: SpeechSynthesizerInterface
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(
        word: Word,
        wordDetailsManager: WordDetailsManagerInterface,
        speechSynthesizer: SpeechSynthesizerInterface
    ) {
        self.word = word
        self.wordDetailsManager = wordDetailsManager
        self.speechSynthesizer = speechSynthesizer
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .speak(let text):
            speak(text)
        case .toggleFavorite:
            wordDetailsManager.toggleFavorite()
        case .updatePartOfSpeech(let value):
            wordDetailsManager.updatePartOfSpeech(value)
        case .toggleShowAddExample:
            isShowAddExample.toggle()
        case .addExample:
            addExample()
        case .removeExample(let offsets):
            wordDetailsManager.removeExample(atOffsets: offsets)
        case .deleteWord:
            wordDetailsManager.deleteWord()
            onOutput?(.finish)
        }
    }

    // MARK: - Private Methods

    private func setupBindings() {
        wordDetailsManager.wordPublisher
            .ifNotNil()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] word in
                self?.word = word
                self?.definitionTextFieldStr = word.definition
            }
            .store(in: &cancellables)

        wordDetailsManager.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorReceived(error, displayType: self?.word == nil ? .page : .alert)
            }
            .store(in: &cancellables)

        $definitionTextFieldStr
            .removeDuplicates()
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.wordDetailsManager.updateDefinition(text)
            }
            .store(in: &cancellables)
    }

    private func addExample() {
        wordDetailsManager.addExample(exampleTextFieldStr)
        exampleTextFieldStr = ""
        isShowAddExample = false
    }

    private func speak(_ text: String?) {
        if let text {
            speechSynthesizer.speak(text)
        }
    }
}
