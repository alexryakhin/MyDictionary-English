import Core
import CoreUserInterface
import CoreNavigation
import Services
import Shared
import Combine

public final class AddIdiomViewModel: DefaultPageViewModel {

    enum Input {
        case save
    }

    enum Output {
        case finish
    }

    var onOutput: ((Output) -> Void)?

    @Published var inputIdiom = ""
    @Published var descriptionField = ""

    private let addIdiomManager: AddIdiomManagerInterface
    private var cancellables = Set<AnyCancellable>()

    public init(
        inputIdiom: String = "",
        addIdiomManager: AddIdiomManagerInterface
    ) {
        self.inputIdiom = inputIdiom
        self.addIdiomManager = addIdiomManager
        super.init()
    }

    func handle(_ input: Input) {
        switch input {
        case .save:
            saveIdiom()
        }
    }

    private func saveIdiom() {
        if !inputIdiom.isEmpty, !descriptionField.isEmpty {
            do {
                try addIdiomManager.addNewIdiom(
                    inputIdiom,
                    definition: descriptionField
                )
                HapticManager.shared.triggerNotification(type: .success)
                onOutput?(.finish)
            } catch {
                errorReceived(error, displayType: .alert)
            }
        } else {
            errorReceived(CoreError.internalError(.inputCannotBeEmpty), displayType: .alert)
        }
    }
}
