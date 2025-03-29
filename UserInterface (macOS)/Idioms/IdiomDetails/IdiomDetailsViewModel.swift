import Foundation
import SwiftUI
import Combine
import Services
import CoreUserInterface__macOS_
import Shared
import Core

final class IdiomDetailsViewModel: DefaultPageViewModel {

    @Published var idiom: Idiom
    @Published var isShowAddExample = false
    @Published var definitionTextFieldStr = ""
    @Published var exampleTextFieldStr = ""

    private let idiomsManager: IdiomDetailsManagerInterface
    private let ttsPlayer: TTSPlayerInterface

    private var cancellables = Set<AnyCancellable>()

    init(
        idiom: Idiom
    ) {
        self.idiom = idiom
        self.idiomsManager = DIContainer.shared.resolver.resolve(IdiomDetailsManagerInterface.self, argument: idiom.id)!
        self.ttsPlayer = DIContainer.shared.resolver.resolve(TTSPlayerInterface.self)!
        self.definitionTextFieldStr = idiom.definition
        super.init()
        setupBindings()
    }

    /// Removes selected idiom from Core Data
    func deleteCurrentIdiom() {
        idiomsManager.deleteIdiom()
    }

    func addExample() {
        idiom.examples.append(exampleTextFieldStr)
        exampleTextFieldStr = ""
        isShowAddExample = false
    }

    func removeExample(atIndex index: Int) {
        idiom.examples.remove(at: index)
    }

    func removeExample(atOffsets offsets: IndexSet) {
        idiom.examples.remove(atOffsets: offsets)
    }

    func speak(_ text: String?) {
        Task {
            do {
                if let text {
                    try await ttsPlayer.play(text)
                }
            } catch {
                errorReceived(error, displayType: .alert)
            }
        }
    }

    func toggleFavorite() {
        idiom.isFavorite.toggle()
    }

    private func setupBindings() {
        $definitionTextFieldStr
            .removeDuplicates()
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.idiom.definition = text
            }
            .store(in: &cancellables)
    }
}
