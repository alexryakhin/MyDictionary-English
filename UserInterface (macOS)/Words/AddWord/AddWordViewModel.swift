import SwiftUI
import Combine

final class AddWordViewModel: BaseViewModel {

    enum Input {
        case save
        case fetchData
        case playInputWord
        case selectPartOfSpeech(PartOfSpeech)
        case selectDefinition(WordDefinition)
        case selectInputLanguage(InputLanguage)
    }

    @Published var inputWord = ""
    @Published var descriptionField = ""

    @Published private(set) var status: FetchingStatus = .blank
    @Published private(set) var definitions: [WordDefinition] = []
    @Published private(set) var selectedDefinition: WordDefinition?
    @Published private(set) var pronunciation: String?
    @Published private(set) var partOfSpeech: PartOfSpeech?

    private let wordnikAPIService: WordnikAPIService
    private let addWordManager: AddWordManager
    private let ttsPlayer: TTSPlayer
    private let translationService: TranslationService
    private let localeLanguageCode: String
    @AppStorage(UDKeys.inputLanguage) var selectedInputLanguage: InputLanguage = .auto
    private var detectedLanguageCode: String?
    private var cancellables = Set<AnyCancellable>()

    init(inputWord: String = "") {
        self.inputWord = inputWord
        self.wordnikAPIService = ServiceManager.shared.wordnikAPIService
        self.addWordManager = ServiceManager.shared.createAddWordManager()
        self.ttsPlayer = ServiceManager.shared.ttsPlayer
        self.translationService = GoogleTranslateService()
        self.localeLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"

        super.init()
        setupBindings()
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
        case .selectInputLanguage(let language):
            selectedInputLanguage = language
        }
    }

    private func fetchData() {
        Task { @MainActor in
            reset()
            do {
                status = .loading

                // Check if input is single word for translation
                let isSingleWord = inputWord.trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .whitespaces)
                    .count == 1

                let wordToSearch: String
                let shouldRequestPronunciation: Bool
                let detectedLanguageCode: String

                if isSingleWord {
                    // Always translate single words to English for API lookup
                    AnalyticsService.shared.logEvent(.translationRequested)
                    
                    let translationResponse: TranslationResponse
                    if selectedInputLanguage.isAuto {
                        // Auto-detect language
                        translationResponse = try await translationService.translateToEnglish(inputWord)
                    } else {
                        // Use selected language
                        translationResponse = try await translationService.translateFromLanguage(inputWord, from: selectedInputLanguage.languageCode)
                    }
                    
                    wordToSearch = translationResponse.text
                    self.detectedLanguageCode = translationResponse.languageCode
                    // Only request pronunciation if the detected language IS English
                    shouldRequestPronunciation = translationResponse.languageCode == "en"
                } else {
                    // Use original input for multi-word phrases
                    wordToSearch = inputWord
                    self.detectedLanguageCode = "en" // Assume English for multi-word phrases
                    shouldRequestPronunciation = true // Always request for multi-word phrases
                }

                AnalyticsService.shared.logEvent(.wordFetchedData)

                // Fetch definitions from Wordnik
                async let definitions = try wordnikAPIService.getDefinitions(
                    for: wordToSearch.lowercased(),
                    params: .init()
                )
                
                // Conditionally fetch pronunciation based on detected language
                let pronunciation: String?
                if shouldRequestPronunciation {
                    pronunciation = try await wordnikAPIService.getPronunciation(
                        for: wordToSearch.lowercased(),
                        params: .init()
                    )
                } else {
                    pronunciation = nil
                }

                self.definitions = try await definitions
                self.pronunciation = pronunciation
                status = .ready
            } catch {
                AnalyticsService.shared.logEvent(.translationFailed)
                errorReceived(error, displayType: .alert, actionText: "Retry") { [weak self] in
                    self?.fetchData()
                }
                status = .error
            }
        }
    }

    private func saveWord() {
        if !inputWord.isEmpty, !descriptionField.isEmpty {
            do {
                // Get the detected language code from the translation response
                let languageCode = detectedLanguageCode ?? "en"
                
                try addWordManager.addNewWord(
                    word: inputWord.capitalizingFirstLetter(),
                    definition: descriptionField.capitalizingFirstLetter(),
                    partOfSpeech: partOfSpeech?.rawValue ?? "unknown",
                    phonetic: pronunciation,
                    examples: selectedDefinition?.examples ?? [],
                    languageCode: languageCode
                )
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
        }
    }
}
