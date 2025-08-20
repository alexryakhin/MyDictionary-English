import Foundation
import Combine
import SwiftUI

final class AddIdiomViewModel: BaseViewModel {

    enum Input {
        case save
        case toggleTag(CDTag)
        case showTagSelection
        case selectInputLanguage(InputLanguage)
    }

    @Published var inputIdiom = ""
    @Published var definitionField = ""
    @Published var selectedTags: [CDTag] = []
    @Published var showingTagSelection = false
    @Published private(set) var availableTags: [CDTag] = []
    @AppStorage(UDKeys.idiomInputLanguage) var selectedInputLanguage: InputLanguage = .english

    private let addIdiomManager: AddIdiomManager = .shared
    private let tagService: TagService = .shared
    private var cancellables = Set<AnyCancellable>()

    init(inputIdiom: String = "") {
        self.inputIdiom = inputIdiom
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .save:
            saveIdiom()
        case .toggleTag(let tag):
            toggleTag(tag)
        case .showTagSelection:
            showingTagSelection = true
        case .selectInputLanguage(let language):
            selectedInputLanguage = language
        }
    }

    private func setupBindings() {
        tagService.$tags
            .receive(on: DispatchQueue.main)
            .assign(to: \.availableTags, on: self)
            .store(in: &cancellables)
        
        tagService.getAllTags()
    }

    private func toggleTag(_ tag: CDTag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }

    private func saveIdiom() {
        if !inputIdiom.isEmpty, !definitionField.isEmpty {
            do {
                try addIdiomManager.addNewIdiom(
                    inputIdiom,
                    definition: definitionField,
                    languageCode: selectedInputLanguage.languageCode,
                    tags: selectedTags
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
