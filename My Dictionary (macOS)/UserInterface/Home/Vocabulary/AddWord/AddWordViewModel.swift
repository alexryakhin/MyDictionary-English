import Combine
import SwiftUI

final class AddWordViewModel: BaseViewModel {

    enum Input {
        case save
        case saveToSharedDictionary(String?)
        case fetchData
        case selectPartOfSpeech(PartOfSpeech)
        case selectDefinition(WordDefinition) // Keep for backward compatibility
        case toggleDefinition(WordDefinition) // New multi-select action
        case toggleTag(CDTag)
        case showTagSelection
        case selectInputLanguage(InputLanguage)
    }

    @Published var inputWord = ""
    @Published var descriptionField = ""
    @Published var selectedTags: [CDTag] = []
    @Published var showingTagSelection = false

    @Published private(set) var status: FetchingStatus = .blank
    @Published private(set) var definitions: [WordDefinition] = []
    @Published private(set) var selectedDefinition: WordDefinition? // Keep for backward compatibility
    @Published private(set) var selectedDefinitions: [WordDefinition] = [] // New multi-select array
    @Published private(set) var pronunciation: String?
    @Published private(set) var partOfSpeech: PartOfSpeech?
    @Published private(set) var availableTags: [CDTag] = []
    @Published private(set) var isTranslating: Bool = false
    @Published private(set) var translatedDefinitions: [WordDefinition] = []
    @AppStorage(UDKeys.translateDefinitions) var translateDefinitions: Bool = false
    @AppStorage(UDKeys.inputLanguage) var selectedInputLanguage: InputLanguage = .auto
    private var detectedLanguageCode: String?

    private let unifiedAPIService: UnifiedAPIService = .shared
    private let addWordManager: AddWordManager = .shared
    private let ttsPlayer: TTSPlayer = .shared
    private let tagService: TagService = .shared
    private let translationService = GoogleTranslateService.shared
    private let dictionaryService = DictionaryService.shared
    private let dataSyncService = DataSyncService.shared
    private let languageDetector = LanguageDetector.shared

    private let localeLanguageCode: String
    private var cancellables = Set<AnyCancellable>()

    init(inputWord: String = "") {
        self.inputWord = inputWord
        self.localeLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"

        // Force translateDefinitions to false for English locales
        if GlobalConstant.isEnglishLanguage {
            self.translateDefinitions = false
        }

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
        case .saveToSharedDictionary(let dictionaryId):
            saveWordToDictionary(dictionaryId)
        case .fetchData:
            fetchData()
        case .selectPartOfSpeech(let partOfSpeech):
            self.partOfSpeech = partOfSpeech
        case .selectDefinition(let definition):
            self.selectedDefinition = definition
        case .toggleDefinition(let definition):
            toggleDefinition(definition)
        case .toggleTag(let tag):
            toggleTag(tag)
        case .showTagSelection:
            showingTagSelection = true
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
                    isTranslating = true
                    AnalyticsService.shared.logEvent(.translationRequested)
                    
                    // Detect language using Apple's Natural Language framework
                    let detectedLanguage = languageDetector.detectLanguage(for: inputWord)
                    
                    // Update selectedInputLanguage from auto to detected language
                    if selectedInputLanguage.isAuto {
                        selectedInputLanguage = detectedLanguage
                    }

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
                    isTranslating = false
                } else {
                    // Use original input for multi-word phrases
                    wordToSearch = inputWord
                    self.detectedLanguageCode = "en" // Assume English for multi-word phrases
                    shouldRequestPronunciation = true // Always request for multi-word phrases
                }

                AnalyticsService.shared.logEvent(.wordFetchedData)

                // Fetch definitions from unified API (randomly chooses between Wordnik and DictionaryAPI.dev)
                async let definitions = try unifiedAPIService.getDefinitions(
                    for: wordToSearch.lowercased(),
                    params: .init()
                )

                // Conditionally fetch pronunciation based on detected language
                let pronunciation: String?
                if shouldRequestPronunciation {
                    pronunciation = try await unifiedAPIService.getPronunciation(
                        for: wordToSearch.lowercased(),
                        params: .init()
                    )
                } else {
                    pronunciation = nil
                }

                self.definitions = try await definitions
                self.pronunciation = pronunciation ?? ""

                // Only translate definitions if:
                // 1. User's locale is not English
                // 2. translateDefinitions setting is enabled
                if !GlobalConstant.isEnglishLanguage && translateDefinitions {
                    await translateDefinitions()
                }

                status = .ready
            } catch {
                AnalyticsService.shared.logEvent(.translationFailed)
                errorReceived(error)
                status = .error
            }
        }
    }

    private func saveWord() {
        saveWordToDictionary(nil)
    }

    private func saveWordToDictionary(_ dictionaryId: String?) {
        // Check if we have either manual definition or selected definitions
        let hasDefinitions = !descriptionField.isEmpty || !selectedDefinitions.isEmpty
        
        if !inputWord.isEmpty, hasDefinitions {
            do {
                // Get the detected language code from the translation response
                let languageCode = detectedLanguageCode ?? "en"

                if let dictionaryId = dictionaryId {
                    // Save to shared dictionary
                    saveWordToSharedDictionary(dictionaryId, languageCode: languageCode)
                } else {
                    // Use new multi-meaning method if we have selected definitions
                    if !selectedDefinitions.isEmpty {
                        let meaningData = selectedDefinitions.map { definition in
                            MeaningData(
                                definition: definition.text,
                                examples: definition.examples
                            )
                        }
                        
                        try addWordManager.addNewWordWithMeanings(
                            word: inputWord.capitalizingFirstLetter(),
                            partOfSpeech: partOfSpeech?.rawValue ?? "unknown",
                            phonetic: pronunciation,
                            meanings: meaningData,
                            tags: selectedTags,
                            languageCode: languageCode
                        )
                    } else {
                        // Fallback to old method for manual definition
                        try addWordManager.addNewWord(
                            word: inputWord.capitalizingFirstLetter(),
                            definition: descriptionField.capitalizingFirstLetter(),
                            partOfSpeech: partOfSpeech?.rawValue ?? "unknown",
                            phonetic: pronunciation,
                            examples: selectedDefinition?.examples ?? [],
                            tags: selectedTags,
                            languageCode: languageCode
                        )
                    }
                    AnalyticsService.shared.logEvent(.wordAdded)
                    dismissPublisher.send()
                }
            } catch {
                errorReceived(error)
            }
        } else {
            errorReceived(CoreError.internalError(.inputCannotBeEmpty))
        }
    }

    private func saveWordToSharedDictionary(_ dictionaryId: String, languageCode: String) {
        // Create meanings from selected definitions or manual input
        let meanings: [WordMeaning]
        if !selectedDefinitions.isEmpty {
            meanings = selectedDefinitions.map { definition in
                WordMeaning(
                    definition: definition.text,
                    examples: definition.examples
                )
            }
        } else {
            meanings = [WordMeaning(
                definition: descriptionField.capitalizingFirstLetter(),
                examples: selectedDefinition?.examples ?? []
            )]
        }
        
        let word = Word(
            id: UUID().uuidString,
            wordItself: inputWord.capitalizingFirstLetter(),
            meanings: meanings,
            partOfSpeech: partOfSpeech?.rawValue ?? "unknown",
            phonetic: pronunciation,
            notes: .empty,
            tags: [], // Don't include tags for shared dictionary words
            difficultyScore: 0,
            languageCode: languageCode,
            isFavorite: false,
            timestamp: Date(),
            updatedAt: Date(),
            isSynced: true
        )

        Task {
            do {
                try await dictionaryService.addWordToSharedDictionary(
                    dictionaryId: dictionaryId,
                    word: word
                )
                AnalyticsService.shared.logEvent(.wordAddedToSharedDictionary)
                dismissPublisher.send()
            } catch {
                errorReceived(error)
            }
        }
    }

    func play(_ text: String?) async throws {
        guard let text else { return }
        try await ttsPlayer.play(text)
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

        tagService.$tags
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tags in
                self?.availableTags = tags
            }
            .store(in: &cancellables)
    }

    private func toggleDefinition(_ definition: WordDefinition) {
        if let index = selectedDefinitions.firstIndex(where: { $0.id == definition.id }) {
            selectedDefinitions.remove(at: index)
        } else {
            selectedDefinitions.append(definition)
        }
        
        // Update backward compatibility property
        selectedDefinition = selectedDefinitions.first
    }
    
    private func reset() {
        withAnimation { [weak self] in
            self?.descriptionField = ""
            self?.status = .blank
            self?.definitions = []
            self?.selectedDefinition = nil
            self?.selectedDefinitions = []
            self?.pronunciation = ""
            self?.partOfSpeech = nil
            self?.selectedTags = []
        }
    }

    private func translateDefinitions() async {
        // Only translate if not English locale and setting is enabled
        guard !GlobalConstant.isEnglishLanguage && translateDefinitions else { return }

        isTranslating = true
        AnalyticsService.shared.logEvent(.translationRequested)

        // Limit to 5 definitions for translation
        let definitionsToTranslate = Array(definitions.prefix(5))

        var translatedDefinitions: [WordDefinition] = []

        // Translate each definition concurrently and maintain order
        await withTaskGroup(of: (Int, WordDefinition?).self) { group in
            for (index, definition) in definitionsToTranslate.enumerated() {
                group.addTask {
                    do {
                        let translatedText = try await self.translationService.translateDefinition(
                            definition.text,
                            to: self.localeLanguageCode
                        )

                        let translatedDefinition = WordDefinition(
                            partOfSpeech: definition.partOfSpeech,
                            text: translatedText,
                            examples: definition.examples
                        )

                        return (index, translatedDefinition)
                    } catch {
                        // Fallback to original definition if translation fails
                        return (index, definition)
                    }
                }
            }

            // Collect results and maintain original order
            var orderedResults: [(Int, WordDefinition?)] = []
            for await (index, translatedDefinition) in group {
                orderedResults.append((index, translatedDefinition))
            }

            // Sort by the original index to maintain order
            orderedResults.sort { $0.0 < $1.0 }

            // Extract the translated definitions in correct order
            translatedDefinitions = orderedResults.compactMap { $0.1 }
        }

        self.translatedDefinitions = translatedDefinitions
        isTranslating = false
        AnalyticsService.shared.logEvent(.translationCompleted)
    }

    private func toggleTag(_ tag: CDTag) {
        if selectedTags.contains(where: { $0.id == tag.id }) {
            selectedTags.removeAll { $0.id == tag.id }
        } else {
            if selectedTags.count < 5 {
                selectedTags.append(tag)
            } else {
                errorReceived(CoreError.internalError(.maxTagsReached))
            }
        }
    }
    

}
