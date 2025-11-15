//
//  StoryLabConfigurationView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI
import Flow

struct StoryLabConfigurationView<ContentPicker: View>: View {
    @ObservedObject private var discoverViewModel: DiscoverViewModel
    private let contentPicker: ContentPicker

    enum InputMode {
        case savedWords
        case customText
    }
    
    @StateObject private var wordsProvider = WordsProvider.shared
    @StateObject private var repository = StoryLabSessionsRepository.shared
    @StateObject private var viewModel = StoryLabConfigurationViewModel()

    @AppStorage(UDKeys.storyLabTargetLanguage) private var targetLanguage: InputLanguage = InputLanguage.english
    @AppStorage(UDKeys.storyLabCEFRLevel) private var cefrLevel: CEFRLevel = CEFRLevel.b1

    @State private var inputMode: InputMode = .savedWords
    @State private var selectedWords: Set<String> = []
    @State private var customText: String = ""
    @State private var pageCount: Int = 1
    @State private var showingWordSelection = false
    @State private var selectedSession: CDStoryLabSession?
    @State private var navigationManager = NavigationManager.shared
    @State private var hasLoggedAppear = false

    @FocusState private var isCustomTextEditing: Bool

    init(discoverViewModel: DiscoverViewModel, contentPicker: ContentPicker) {
        self.discoverViewModel = discoverViewModel
        self.contentPicker = contentPicker
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Past Sessions Section
                pastSessionsSection
                
                // Input Content Section
                inputContentSection
                
                // Settings Section
                settingsSection

                generateButton
            }
            .padding(vertical: 12, horizontal: 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .groupedBackground()
        .navigation(
            title: Loc.Discover.title,
            mode: .regular,
            trailingContent: {
                contentPicker
            },
            bottomContent: {
                Text(Loc.StoryLab.Configuration.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker(Loc.StoryLab.Configuration.inputMode, selection: $inputMode) {
                    Text(Loc.StoryLab.Configuration.myWords).tag(InputMode.savedWords)
                    Text(Loc.StoryLab.Configuration.customText).tag(InputMode.customText)
                }
                .pickerStyle(.segmented)
            }
        )
        .sheet(isPresented: $showingWordSelection) {
            StoryLabWordSelectionView(selectedWords: $selectedWords, targetLanguage: targetLanguage)
        }
        .onChange(of: targetLanguage) {
            selectedWords.removeAll()
        }
        .onAppear {
            guard !hasLoggedAppear else { return }
            hasLoggedAppear = true
            AnalyticsService.shared.logEvent(
                .storyLabConfigurationOpened,
                parameters: [
                    "input_mode": analyticsInputModeKey(inputMode),
                    "saved_words_available": wordsProvider.words.count,
                    "sessions_count": repository.sessions.count
                ]
            )
        }
    }

    // MARK: - Past Sessions Section
    
    private var pastSessionsSection: some View {
        CustomSectionView(header: Loc.StoryLab.Configuration.pastSessions) {
            if repository.sessions.isEmpty {
                ContentUnavailableView(
                    Loc.StoryLab.Configuration.emptySessionsTitle,
                    systemImage: "book.closed",
                    description: Text(Loc.StoryLab.Configuration.emptySessionsDescription)
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(repository.sessions.prefix(3))) { session in
                        Button {
                            viewModel.openSession(session)
                        } label: {
                            StoryLabSessionRow(session: session)
                                .padding(12)
                                .clippedWithBackground(
                                    Color.tertiarySystemGroupedBackground,
                                    in: .rect(cornerRadius: 16)
                                )
                                .contentShape(.rect(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } trailingContent: {
            if repository.sessions.count > 3 {
                HeaderButton(Loc.Actions.viewAll, size: .small) {
                    navigationManager.navigate(to: .storyLabHistory)
                }
            }
        }
    }
    
    // MARK: - Input Content Section
    
    @ViewBuilder
    private var inputContentSection: some View {
        if inputMode == .savedWords {
            savedWordsSection
        } else {
            customTextSection
        }
    }
    
    private var savedWordsSection: some View {
        CustomSectionView(
            header: Loc.StoryLab.Configuration.selectWords,
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if selectedWords.isEmpty {
                    ActionButton(Loc.Actions.select, systemImage: "plus.circle") {
                        showingWordSelection = true
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Loc.Plurals.Words.wordsCount(selectedWords.count))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HFlow(alignment: .top, spacing: 8) {
                            ForEach(Array(selectedWords), id: \.self) { word in
                                HStack(spacing: 4) {
                                    Text(word)
                                        .font(.caption)
                                    Button {
                                        selectedWords.remove(word)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        } trailingContent: {
            if selectedWords.isNotEmpty {
                HeaderButton(Loc.Actions.edit, size: .small) {
                    showingWordSelection = true
                }
            }
        }
    }
    
    private var customTextSection: some View {
        CustomSectionView(
            header: Loc.StoryLab.Configuration.customText,
        ) {
            TextField(
                Loc.StoryLab.Configuration.customTextPlaceholder,
                text: $customText,
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .focused($isCustomTextEditing)
        } trailingContent: {
            if isCustomTextEditing {
                HeaderButton(Loc.Actions.done, action: endEditing)
            }
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        CustomSectionView(header: Loc.Actions.settings, hPadding: .zero) {
            FormWithDivider {
                // Target Language
                CellWrapper {
                    Text(Loc.StoryLab.Configuration.targetLanguage)
                        .font(.headline)
                        .foregroundStyle(.primary)
                } trailingContent: {
                    HeaderButtonMenu(targetLanguage.displayName) {
                        Picker(Loc.StoryLab.Configuration.targetLanguage, selection: $targetLanguage) {
                            ForEach(InputLanguage.allCasesSorted, id: \.self) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                }

                // CEFR Level
                CellWrapper {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Loc.StoryLab.Configuration.cefrLevel)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(cefrLevel.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } trailingContent: {
                    HeaderButtonMenu(cefrLevel.displayName) {
                        Picker(Loc.StoryLab.Configuration.cefrLevel, selection: $cefrLevel) {
                            ForEach(CEFRLevel.allCases, id: \.self) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                }
                // Page Count
                CellWrapper {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Loc.StoryLab.Configuration.pageCount)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(Loc.Plurals.pagesCount(pageCount))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } trailingContent: {
                    Stepper("", value: $pageCount, in: 1...4)
                        .labelsHidden()
                }
            }
        }
    }
    
    // MARK: - Generate Button
    
    private var generateButton: some View {
        VStack(spacing: 12) {
            if case .generating = viewModel.loadingStatus {
                ProgressView()
                    .progressViewStyle(.circular)
                Text(Loc.StoryLab.Configuration.generating)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if case .error(let message) = viewModel.loadingStatus {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                
                ActionButton(
                    Loc.Actions.retry,
                    style: .borderedProminent
                ) {
                    generateStory()
                }
            } else {
                ActionButton(
                    Loc.StoryLab.Configuration.generateStory,
                    style: .borderedProminent
                ) {
                    generateStory()
                }
                .disabled(!isValidConfiguration)
            }
        }
    }
    
    // MARK: - Validation
    
    private var isValidConfiguration: Bool {
        switch inputMode {
        case .savedWords:
            return selectedWords.count >= 5
        case .customText:
            return !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    // MARK: - Actions
    
    private func generateStory() {
        let config: StoryLabConfig
        
        switch inputMode {
        case .savedWords:
            config = StoryLabConfig(
                savedWords: Array(selectedWords),
                customText: nil,
                targetLanguage: targetLanguage,
                cefrLevel: cefrLevel,
                pageCount: pageCount
            )
        case .customText:
            config = StoryLabConfig(
                savedWords: nil,
                customText: customText.trimmingCharacters(in: .whitespacesAndNewlines),
                targetLanguage: targetLanguage,
                cefrLevel: cefrLevel,
                pageCount: pageCount
            )
        }
        
        AnalyticsService.shared.logEvent(
            .storyLabGenerationRequested,
            parameters: analyticsParameters(for: config, inputMode: inputMode)
        )
        viewModel.handle(.generateStory(config))
    }

    private func analyticsParameters(for config: StoryLabConfig, inputMode: InputMode) -> [String: Any] {
        var params: [String: Any] = [
            "target_language": config.targetLanguage.rawValue,
            "cefr_level": config.cefrLevel.rawValue,
            "page_count": config.pageCount,
            "input_mode": analyticsInputModeKey(inputMode)
        ]

        if let words = config.savedWords {
            params["saved_words_count"] = words.count
        }

        if let text = config.customText {
            params["custom_text_length"] = text.count
        }

        return params
    }

    private func analyticsInputModeKey(_ mode: InputMode) -> String {
        switch mode {
        case .savedWords:
            return "saved_words"
        case .customText:
            return "custom_text"
        }
    }
}
