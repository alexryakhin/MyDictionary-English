import Core
import CoreUserInterface
import CoreNavigation
import Services
import Shared
import Combine

public final class IdiomDetailsViewModel: DefaultPageViewModel {

    enum Input {
        case speak(String?)
        case toggleFavorite
        case addExample(String)
        case updateExample(at: Int, text: String)
        case removeExample(at: Int)
        case deleteIdiom
    }

    enum Output {
        case finish
    }

    var onOutput: ((Output) -> Void)?

    @Published var idiom: Idiom

    // MARK: - Private Properties

    private let idiomDetailsManager: IdiomDetailsManagerInterface
    private let speechSynthesizer: SpeechSynthesizerInterface
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(
        idiom: Idiom,
        idiomDetailsManager: IdiomDetailsManagerInterface,
        speechSynthesizer: SpeechSynthesizerInterface
    ) {
        self.idiom = idiom
        self.idiomDetailsManager = idiomDetailsManager
        self.speechSynthesizer = speechSynthesizer
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .speak(let text):
            speak(text)
            AnalyticsService.shared.logEvent(.listenToIdiomTapped)
        case .toggleFavorite:
            idiom.isFavorite.toggle()
            AnalyticsService.shared.logEvent(.idiomFavoriteTapped(isFavorite: idiom.isFavorite))
        case .addExample(let example):
            guard !example.isEmpty else {
                errorReceived(CoreError.internalError(.inputCannotBeEmpty), displayType: .alert)
                return
            }
            idiom.examples.append(example)
            AnalyticsService.shared.logEvent(.idiomExampleAdded)
        case .updateExample(let index, let example):
            guard !example.isEmpty else {
                errorReceived(CoreError.internalError(.inputCannotBeEmpty), displayType: .alert)
                return
            }
            idiom.examples[index] = example
            AnalyticsService.shared.logEvent(.idiomExampleUpdated)
        case .removeExample(let index):
            idiom.examples.remove(at: index)
            AnalyticsService.shared.logEvent(.idiomExampleRemoved)
        case .deleteIdiom:
            showAlert(
                withModel: .init(
                    title: "Delete idiom",
                    message: "Are you sure you want to delete this idiom?",
                    actionText: "Cancel",
                    destructiveActionText: "Delete",
                    action: {},
                    destructiveAction: { [weak self] in
                        self?.idiomDetailsManager.deleteIdiom()
                        AnalyticsService.shared.logEvent(.idiomRemoved)
                        self?.onOutput?(.finish)
                    }
                )
            )
        }
    }

    // MARK: - Private Methods

    private func setupBindings() {
        idiomDetailsManager.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorReceived(error, displayType: self?.idiom == nil ? .page : .alert)
            }
            .store(in: &cancellables)

        $idiom
            .removeDuplicates()
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] idiom in
                self?.idiomDetailsManager.updateIdiom(idiom)
            }
            .store(in: &cancellables)
    }

    private func speak(_ text: String?) {
        if let text {
            speechSynthesizer.speak(text)
        }
    }
}
