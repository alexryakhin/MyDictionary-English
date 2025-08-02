import Combine
import SwiftUI

final class AddWordViewModel: BaseViewModel {

    enum Input {
        case save
        case fetchData
        case playInputWord
        case selectPartOfSpeech(PartOfSpeech)
        case selectDefinition(WordDefinition)
        case toggleTag(CDTag)
        case showTagSelection
    }

    @Published var inputWord = ""
    @Published var descriptionField = ""

    @Published private(set) var status: FetchingStatus = .blank
    @Published private(set) var definitions: [WordDefinition] = []
    @Published private(set) var selectedDefinition: WordDefinition?
    @Published private(set) var pronunciation: String?
    @Published private(set) var partOfSpeech: PartOfSpeech?
    @Published var selectedTags: [CDTag] = []
    @Published var showingTagSelection = false
    @Published private(set) var availableTags: [CDTag] = []

    private let wordnikAPIService: WordnikAPIService
    private let addWordManager: AddWordManager
    private let ttsPlayer: TTSPlayer
    private let tagService: TagService
    private var cancellables = Set<AnyCancellable>()

    init(inputWord: String = "") {
        self.inputWord = inputWord
        self.wordnikAPIService = ServiceManager.shared.wordnikAPIService
        self.addWordManager = ServiceManager.shared.createAddWordManager()
        self.ttsPlayer = ServiceManager.shared.ttsPlayer
        self.tagService = ServiceManager.shared.tagService

        super.init()
        setupBindings()
        loadTags()
        if !inputWord.isEmpty {
            fetchData()
        }
    }

    func handle(_ input: Input) {
        switch input {
        case .save:
            saveWord()
        case .fetchData:
            fetchData()
        case .playInputWord:
            play(inputWord)
        case .selectPartOfSpeech(let partOfSpeech):
            self.partOfSpeech = partOfSpeech
        case .selectDefinition(let definition):
            self.selectedDefinition = definition
        case .toggleTag(let tag):
            toggleTag(tag)
        case .showTagSelection:
            showingTagSelection = true
        }
    }

    private func fetchData() {
        Task { @MainActor in
            reset()
            do {
                guard inputWord.isValidEnglishWordOrPhrase else {
                    throw CoreError.internalError(.inputIsNotAWord)
                }
                status = .loading
                AnalyticsService.shared.logEvent(.wordFetchedData)
                async let definitions = try wordnikAPIService.getDefinitions(
                    for: inputWord.lowercased(),
                    params: .init()
                )
                async let pronunciation = try wordnikAPIService.getPronunciation(
                    for: inputWord.lowercased(),
                    params: .init()
                )
                self.definitions = try await definitions
                self.pronunciation = try await pronunciation
                status = .ready
            } catch {
                errorReceived(error, displayType: .alert, actionText: "Retry") { [weak self] in
                    self?.fetchData()
                }
                status = .error
            }
        }
    }

    private func saveWord() {
        guard inputWord.isCorrect else {
            errorReceived(CoreError.internalError(.inputIsNotAWord), displayType: .alert)
            return
        }

        if !inputWord.isEmpty, !descriptionField.isEmpty {
            do {
                try addWordManager.addNewWord(
                    word: inputWord.capitalizingFirstLetter(),
                    definition: descriptionField.capitalizingFirstLetter(),
                    partOfSpeech: partOfSpeech?.rawValue ?? "unknown",
                    phonetic: pronunciation,
                    examples: selectedDefinition?.examples ?? [],
                    tags: selectedTags
                )
                HapticManager.shared.triggerNotification(type: .success)
                AnalyticsService.shared.logEvent(.wordAdded)
                dismissPublisher.send()
            } catch {
                errorReceived(error, displayType: .alert)
            }
        } else {
            errorReceived(CoreError.internalError(.inputCannotBeEmpty), displayType: .alert)
        }
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

    private func setupBindings() {
        $inputWord
            .dropFirst()
            .removeDuplicates()
            .map(\.isEmpty)
            .sink { [weak self] isEmpty in
                if isEmpty {
                    self?.reset()
                }
            }
            .store(in: &cancellables)

        $selectedDefinition
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] definition in
                self?.descriptionField = definition.text
                self?.partOfSpeech = definition.partOfSpeech
            }
            .store(in: &cancellables)
    }

    private func reset() {
        withAnimation { [weak self] in
            self?.descriptionField = ""
            self?.status = .blank
            self?.definitions = []
            self?.selectedDefinition = nil
            self?.pronunciation = nil
            self?.partOfSpeech = nil
            self?.selectedTags = []
        }
    }
    
    private func loadTags() {
        availableTags = tagService.getAllTags()
    }
    
    private func toggleTag(_ tag: CDTag) {
        if selectedTags.contains(where: { $0.id == tag.id }) {
            selectedTags.removeAll { $0.id == tag.id }
        } else {
            if selectedTags.count < 5 {
                selectedTags.append(tag)
            } else {
                errorReceived(CoreError.internalError(.maxTagsReached), displayType: .alert)
            }
        }
    }
}
