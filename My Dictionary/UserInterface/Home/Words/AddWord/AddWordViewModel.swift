import Combine
import SwiftUI

final class AddWordViewModel: BaseViewModel {

    enum Input {
        case save
        case saveToSharedDictionary(String?)
        case fetchData
        case playInputWord
        case selectPartOfSpeech(PartOfSpeech)
        case selectDefinition(WordDefinition)
        case toggleTag(CDTag)
        case showTagSelection
        case selectInputLanguage(InputLanguage)
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
    @Published private(set) var isTranslating: Bool = false
    @Published private(set) var translatedDefinitions: [WordDefinition] = []
    @AppStorage(UDKeys.translateDefinitions) var translateDefinitions: Bool = false
    @AppStorage(UDKeys.inputLanguage) var selectedInputLanguage: InputLanguage = .auto
    private var detectedLanguageCode: String?

    private let wordnikAPIService: WordnikAPIService = .shared
    private let addWordManager: AddWordManager = .shared
    private let ttsPlayer: TTSPlayer = .shared
    private let tagService: TagService = .shared
    private let translationService = GoogleTranslateService.shared
    private let dictionaryService = DictionaryService.shared
    private let dataSyncService = DataSyncService.shared

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
                errorReceived(error, displayType: .alert, actionText: "Retry") { [weak self] in
                    self?.fetchData()
                }
                status = .error
            }
        }
    }

    private func saveWord() {
        saveWordToDictionary(nil)
    }
    
    private func saveWordToDictionary(_ dictionaryId: String?) {
        print("🔍 [AddWordViewModel] saveWordToDictionary called")
        print("📝 [AddWordViewModel] inputWord: '\(inputWord)'")
        print("📝 [AddWordViewModel] descriptionField: '\(descriptionField)'")
        print("📝 [AddWordViewModel] dictionaryId: \(dictionaryId ?? "nil (private)")")
        
        if !inputWord.isEmpty, !descriptionField.isEmpty {
            do {
                // Get the detected language code from the translation response
                let languageCode = detectedLanguageCode ?? "en"
                print("🌐 [AddWordViewModel] Language code: \(languageCode)")
                
                if let dictionaryId = dictionaryId {
                    // Save to shared dictionary
                    print("💾 [AddWordViewModel] Saving to shared dictionary: \(dictionaryId)")
                    saveWordToSharedDictionary(dictionaryId, languageCode: languageCode)
                } else {
                    // Save to private dictionary
                    print("💾 [AddWordViewModel] Calling addWordManager.addNewWord")
                    try addWordManager.addNewWord(
                        word: inputWord.capitalizingFirstLetter(),
                        definition: descriptionField.capitalizingFirstLetter(),
                        partOfSpeech: partOfSpeech?.rawValue ?? "unknown",
                        phonetic: pronunciation,
                        examples: selectedDefinition?.examples ?? [],
                        tags: selectedTags,
                        languageCode: languageCode
                    )
                    HapticManager.shared.triggerNotification(type: .success)
                    AnalyticsService.shared.logEvent(.wordAdded)
                    dismissPublisher.send()

                    print("✅ [AddWordViewModel] Word saved to private dictionary")
                    
                    // Manually trigger sync to Firestore
                    if let userId = AuthenticationService.shared.userId {
                        print("🔄 [AddWordViewModel] Manually triggering sync to Firestore")
                        Task {
                            do {
                                try await dataSyncService.syncPrivateDictionaryToFirestore(userId: userId)
                                print("✅ [AddWordViewModel] Manual sync completed successfully")
                            } catch {
                                errorReceived(error, displayType: .alert)
                                print("❌ [AddWordViewModel] Manual sync failed: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        print("❌ [AddWordViewModel] No userId available for manual sync")
                    }
                }
            } catch {
                print("❌ [AddWordViewModel] Error saving word: \(error.localizedDescription)")
                errorReceived(error, displayType: .alert)
            }
        } else {
            print("❌ [AddWordViewModel] Input validation failed")
            errorReceived(CoreError.internalError(.inputCannotBeEmpty), displayType: .alert)
        }
    }
    
    private func saveWordToSharedDictionary(_ dictionaryId: String, languageCode: String) {
        let word = Word(
            id: UUID().uuidString,
            wordItself: inputWord.capitalizingFirstLetter(),
            definition: descriptionField.capitalizingFirstLetter(),
            partOfSpeech: partOfSpeech?.rawValue ?? "unknown",
            phonetic: pronunciation,
            examples: selectedDefinition?.examples ?? [],
            tags: [], // Don't include tags for shared dictionary words
            difficultyLevel: 0,
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
                HapticManager.shared.triggerNotification(type: .success)
                AnalyticsService.shared.logEvent(.wordAddedToSharedDictionary)
                dismissPublisher.send()
            } catch {
                errorReceived(error, displayType: .alert)
            }
        }
    }

    private func play(_ text: String?) {
        Task { @MainActor in
            guard let text else { return }

            do {
                // Here playing is only for English words anyway
                try await ttsPlayer.play(text, targetLanguage: "en")
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

        tagService.$tags
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tags in
                self?.availableTags = tags
            }
            .store(in: &cancellables)
    }

    private func reset() {
        withAnimation { [weak self] in
            self?.descriptionField = ""
            self?.status = .blank
            self?.definitions = []
            self?.selectedDefinition = nil
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
                errorReceived(CoreError.internalError(.maxTagsReached), displayType: .alert)
            }
        }
    }
}
