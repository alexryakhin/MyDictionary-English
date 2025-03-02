import Foundation
import SwiftUI
import Combine
import CoreData

final class IdiomDetailsViewModel: ViewModel {

    @Binding var idiom: Idiom?
    @Published var isShowAddExample = false
    @Published var definitionTextFieldStr = ""
    @Published var exampleTextFieldStr = ""

    private let idiomsManager: IdiomsManagerInterface
    private let speechSynthesizer = SpeechSynthesizer.shared

    private var cancellables = Set<AnyCancellable>()

    init(
        idiom: Binding<Idiom?>,
        idiomsManager: IdiomsManagerInterface
    ) {
        self._idiom = idiom
        self.idiomsManager = idiomsManager
        self.definitionTextFieldStr = idiom.wrappedValue?.definition ?? ""
        super.init()
        setupBindings()
    }

    /// Removes selected idiom from Core Data
    func deleteCurrentIdiom() {
        guard let idiom else { return }
        idiomsManager.deleteIdiom(idiom)
        saveContext()
        self.idiom = nil
    }

    func addExample() {
        do {
            try idiom?.addExample(exampleTextFieldStr)
            saveContext()
            exampleTextFieldStr = ""
            isShowAddExample = false
        } catch {
            handleError(error)
        }
    }

    func removeExample(_ example: String) {
        do {
            try idiom?.removeExample(example)
            saveContext()
        } catch {
            handleError(error)
        }
    }

    func removeExample(atOffsets offsets: IndexSet) {
        do {
            try idiom?.removeExample(atOffsets: offsets)
            saveContext()
        } catch {
            handleError(error)
        }
    }

    func speak(_ text: String?) {
        if let text {
            speechSynthesizer.speak(text)
        }
    }

    func toggleFavorite() {
        idiom?.isFavorite.toggle()
        saveContext()
    }

    private func setupBindings() {
        $definitionTextFieldStr
            .removeDuplicates()
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.idiom?.definition = text
                self?.saveContext()
            }
            .store(in: &cancellables)
    }

    private func saveContext() {
        do {
            try idiomsManager.saveContext()
        } catch {
            handleError(error)
        }
    }
}
