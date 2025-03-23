import Core
import CoreUserInterface
import CoreNavigation
import Services
import Shared
import Combine

public final class WordDetailsViewModel: DefaultPageViewModel {

    enum Input {
        case play(String?)
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
    private let ttsPlayer: TTSPlayerInterface
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(
        word: Word,
        wordDetailsManager: WordDetailsManagerInterface,
        ttsPlayer: TTSPlayerInterface
    ) {
        self.word = word
        self.wordDetailsManager = wordDetailsManager
        self.ttsPlayer = ttsPlayer
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .play(let text):
            play(text)
        case .toggleFavorite:
            wordDetailsManager.toggleFavorite()
            AnalyticsService.shared.logEvent(.wordFavoriteTapped)
        case .updatePartOfSpeech(let value):
            wordDetailsManager.updatePartOfSpeech(value)
            AnalyticsService.shared.logEvent(.partOfSpeechChanged)
        case .toggleShowAddExample:
            isShowAddExample.toggle()
        case .addExample:
            addExample()
            AnalyticsService.shared.logEvent(.wordExampleAdded)
        case .removeExample(let offsets):
            wordDetailsManager.removeExample(atOffsets: offsets)
            AnalyticsService.shared.logEvent(.wordExampleRemoved)
        case .deleteWord:
            showAlert(
                withModel: .init(
                    title: "Delete word",
                    message: "Are you sure you want to delete this word?",
                    actionText: "Cancel",
                    destructiveActionText: "Delete",
                    action: {},
                    destructiveAction: { [weak self] in
                        self?.wordDetailsManager.deleteWord()
                        self?.onOutput?(.finish)
                    }
                )
            )
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

    private func play(_ text: String?) {
        Task { @MainActor in
            guard let text else { return }

            do {
                try await ttsPlayer.play(text)
            } catch {
                errorReceived(error, displayType: .alert)
            }
        }
    }
}
