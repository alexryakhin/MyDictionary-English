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
        case toggleShowAddExample
        case addExample
        case removeExample(IndexSet)
        case deleteIdiom
    }

    enum Output {
        case finish
    }

    var onOutput: ((Output) -> Void)?

    @Published private(set) var idiom: Idiom
    @Published private(set) var isShowAddExample = false
    @Published var definitionTextFieldStr = ""
    @Published var exampleTextFieldStr = ""

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
        case .toggleFavorite:
            idiomDetailsManager.toggleFavorite()
        case .toggleShowAddExample:
            isShowAddExample.toggle()
        case .addExample:
            addExample()
        case .removeExample(let offsets):
            idiomDetailsManager.removeExample(atOffsets: offsets)
        case .deleteIdiom:
            idiomDetailsManager.deleteIdiom()
            onOutput?(.finish)
        }
    }

    // MARK: - Private Methods

    private func setupBindings() {
        idiomDetailsManager.idiomPublisher
            .ifNotNil()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] idiom in
                self?.idiom = idiom
                self?.definitionTextFieldStr = idiom.definition
            }
            .store(in: &cancellables)

        idiomDetailsManager.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorReceived(error, displayType: self?.idiom == nil ? .page : .alert)
            }
            .store(in: &cancellables)

        $definitionTextFieldStr
            .removeDuplicates()
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.idiomDetailsManager.updateDefinition(text)
            }
            .store(in: &cancellables)
    }

    private func addExample() {
        idiomDetailsManager.addExample(exampleTextFieldStr)
        exampleTextFieldStr = ""
        isShowAddExample = false
    }

    private func speak(_ text: String?) {
        if let text {
            speechSynthesizer.speak(text)
        }
    }
}
