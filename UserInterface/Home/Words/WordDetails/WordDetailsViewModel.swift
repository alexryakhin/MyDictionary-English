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
        case updatePartOfSpeech(PartOfSpeech)
        case addExample(String)
        case updateExample(at: Int, text: String)
        case removeExample(at: Int)
        case deleteWord
    }

    enum Output {
        case finish
    }

    var onOutput: ((Output) -> Void)?


    @Published var word: Word

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
            word.isFavorite.toggle()
            AnalyticsService.shared.logEvent(.wordFavoriteTapped)
        case .updatePartOfSpeech(let value):
            word.partOfSpeech = value
            AnalyticsService.shared.logEvent(.partOfSpeechChanged)
        case .addExample(let example):
            guard !example.isEmpty else {
                errorReceived(CoreError.internalError(.inputCannotBeEmpty), displayType: .alert)
                return
            }
            word.examples.append(example)
            AnalyticsService.shared.logEvent(.wordExampleAdded)
        case .updateExample(let index, let example):
            guard !example.isEmpty else {
                errorReceived(CoreError.internalError(.inputCannotBeEmpty), displayType: .alert)
                return
            }
            word.examples[index] = example
            AnalyticsService.shared.logEvent(.wordExampleUpdated)
        case .removeExample(let index):
            word.examples.remove(at: index)
            AnalyticsService.shared.logEvent(.wordExampleRemoved)
        case .deleteWord:
            showAlert(
                withModel: .init(
                    title: "Delete word",
                    message: "Are you sure you want to delete this word?",
                    actionText: "Cancel",
                    destructiveActionText: "Delete",
                    action: {
                        AnalyticsService.shared.logEvent(.wordRemovingCanceled)
                    },
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
        wordDetailsManager.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorReceived(error, displayType: self?.word == nil ? .page : .alert)
            }
            .store(in: &cancellables)

        $word
            .removeDuplicates()
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] word in
                self?.wordDetailsManager.updateWord(word)
            }
            .store(in: &cancellables)
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
