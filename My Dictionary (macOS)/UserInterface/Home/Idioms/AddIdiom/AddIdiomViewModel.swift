import Combine

final class AddIdiomViewModel: BaseViewModel {

    enum Input {
        case save
    }

    @Published var inputIdiom = ""
    @Published var definitionField = ""

    private let addIdiomManager: AddIdiomManager = .shared
    private var cancellables = Set<AnyCancellable>()

    init(inputIdiom: String = "") {
        self.inputIdiom = inputIdiom
        super.init()
    }

    func handle(_ input: Input) {
        switch input {
        case .save:
            saveIdiom()
        }
    }

    private func saveIdiom() {
        if !inputIdiom.isEmpty, !definitionField.isEmpty {
            do {
                try addIdiomManager.addNewIdiom(
                    inputIdiom,
                    definition: definitionField
                )
                
                AnalyticsService.shared.logEvent(.idiomAdded)
                dismissPublisher.send()
            } catch {
                errorReceived(error)
            }
        } else {
            errorReceived(CoreError.internalError(.inputCannotBeEmpty))
        }
    }
}
