//
//  StoryLabConfigurationView.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import SwiftUI
import Flow

struct StoryLabConfigurationView: View {
    
    enum InputMode {
        case savedWords
        case customText
    }
    
    var viewModel: StoryLabViewModel?
    @StateObject private var wordsProvider = WordsProvider.shared
    @StateObject private var repository = StoryLabSessionsRepository()
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var internalViewModel = StoryLabViewModel()
    
    private var activeViewModel: StoryLabViewModel {
        viewModel ?? internalViewModel
    }
    
    init(viewModel: StoryLabViewModel? = nil) {
        self.viewModel = viewModel
    }
    
    @State private var inputMode: InputMode = .savedWords
    @State private var selectedWords: Set<String> = []
    @State private var customText: String = ""
    @State private var targetLanguage: InputLanguage = .english
    @State private var cefrLevel: CEFRLevel = .b1
    @State private var pageCount: Int = 1
    @State private var showingWordSelection = false
    @State private var selectedSession: CDStoryLabSession?
    @FocusState private var isCustomTextEditing: Bool

    @State private var navigationManager = NavigationManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Past Sessions Section
                pastSessionsSection
                
                // Input Content Section
                inputContentSection
                
                // Settings Section
                settingsSection
            }
            .padding(vertical: 12, horizontal: 16)
        }
        .groupedBackground()
        .navigation(
            title: Loc.StoryLab.title,
            mode: .large,
            showsBackButton: true,
            bottomContent: {
                Text(Loc.StoryLab.Configuration.description)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker(Loc.StoryLab.Configuration.inputMode, selection: $inputMode) {
                    Text(Loc.StoryLab.Configuration.myWords).tag(InputMode.savedWords)
                    Text(Loc.StoryLab.Configuration.customText).tag(InputMode.customText)
                }
                .pickerStyle(.segmented)
            }
        )
        .onReceive(activeViewModel.dismissPublisher) {
            dismiss()
        }
        .sheet(isPresented: $showingWordSelection) {
            StoryLabWordSelectionView(selectedWords: $selectedWords, targetLanguage: targetLanguage)
        }
        .safeAreaBarIfAvailable {
            generateButton
                .padding(vertical: 12, horizontal: 16)
        }
        .onAppear {
            // Initialize target language from viewModel's config if available
            if let config = activeViewModel.config,
               targetLanguage != config.targetLanguage {
                targetLanguage = config.targetLanguage
            } else {
                // Set default target language to English
                targetLanguage = .english
            }
        }
        .onChange(of: targetLanguage) {
            selectedWords.removeAll()
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
                            selectedSession = session
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
                    navigationManager.navigationPath.append(NavigationDestination.storyLabHistory)
                }
            }
        }
        .sheet(item: $selectedSession) { session in
            if let storySession = session.toStorySession(),
               let story = session.story,
               let config = session.config {
                // Show reading view if incomplete, results if complete
                if storySession.isComplete {
                    StoryLabResultsView(
                        session: storySession,
                        story: story,
                        config: config,
                        showStreak: false,
                        currentDayStreak: nil
                    )
                } else {
                    // Resume from current page
                    StoryLabReadingView(config: config)
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
            if case .generating = activeViewModel.loadingStatus {
                ProgressView()
                    .progressViewStyle(.circular)
                Text(Loc.StoryLab.Configuration.generating)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if case .error(let message) = activeViewModel.loadingStatus {
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
        
        activeViewModel.handle(.generateStory(config))
    }
}
