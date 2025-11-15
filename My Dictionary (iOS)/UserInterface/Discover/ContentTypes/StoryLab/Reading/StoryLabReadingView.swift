//
//  StoryLabReadingView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct StoryLabReadingView: View {
    private let config: StoryLabReadingConfig
    @StateObject private var viewModel: StoryLabReadingViewModel
    @StateObject private var ttsPlayer = TTSPlayer.shared
    @State private var discoveredWord: InteractiveText.SelectedWord?
    @State private var hasLoggedAppear = false

    init(config: StoryLabReadingConfig) {
        self.config = config
        _viewModel = StateObject(wrappedValue: StoryLabReadingViewModel(config: config))
    }

    var body: some View {
        Group {
            if let story = viewModel.story, let session = viewModel.session {
                readingContentView(story: story, session: session)
            } else {
                loadingView
            }
        }
        .navigation(
            title: viewModel.story?.title ?? Loc.StoryLab.title,
            mode: .regular,
            showsBackButton: true,
            bottomContent: {
                if let session = viewModel.session, let story = viewModel.story {
                    Text(Loc.StoryLab.Reading.page(session.currentPageIndex + 1, story.pages.count))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        )
        .sheet(item: $discoveredWord) { word in
            let addWordConfig = AddWordConfig(
                input: word.text,
                inputLanguage: viewModel.config?.targetLanguage ?? .english,
                selectedDictionaryId: nil,
                isWord: true
            )

            AddWordView(config: addWordConfig)
                .onDisappear {
                    if let savedWord = discoveredWord?.text {
                        viewModel.onWordSaved?(savedWord)
                    }
                }
        }
        .onAppear {
            guard !hasLoggedAppear else { return }
            hasLoggedAppear = true
            if let session = viewModel.session, let story = viewModel.story {
                AnalyticsService.shared.logEvent(
                    .storyLabReadingOpened,
                    parameters: [
                        "session_id": session.id.uuidString,
                        "title": story.title,
                        "page_index": session.currentPageIndex,
                        "pages_total": story.pages.count
                    ]
                )
            }
        }
        .interactiveDismissDisabled()
        .onDisappear {
            ttsPlayer.stop()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(.circular)

            Text(Loc.StoryLab.Configuration.generating)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .groupedBackground()
    }

    // MARK: - Reading Content View

    private func readingContentView(story: AIStoryResponse, session: StorySession) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                storyContentSection()

                if let currentPage = viewModel.currentPage {
                    StoryLabQuizView(
                        page: currentPage,
                        pageIndex: session.currentPageIndex,
                        viewModel: viewModel
                    )
                }

                navigationSection(session: session, totalPages: story.pages.count)
            }
            .padding(vertical: 12, horizontal: 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .groupedBackground()
    }

    // MARK: - Story Content Section

    private func storyContentSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let currentPage = viewModel.currentPage {
                HighlightedStoryText(
                    text: currentPage.storyText,
                    font: .body,
                    currentChunk: ttsPlayer.currentPlayingChunk,
                    sourceLanguageCode: viewModel.config?.targetLanguage.rawValue ?? InputLanguage.english.rawValue
                )
                .onDisappear {
                    ttsPlayer.stop()
                }
            }

            if let currentPage = viewModel.currentPage {
                playButton(for: currentPage.storyText)
            }
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }

    // MARK: - Play Button

    private func playButton(for text: String) -> some View {
        ActionButton(
            ttsPlayer.isPlaying ? Loc.StoryLab.Reading.pause : Loc.StoryLab.Reading.listenToStory,
            systemImage: ttsPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill"
        ) {
            Task {
                if ttsPlayer.isPlaying {
                    ttsPlayer.pause()
                } else {
                    do {
                        try await ttsPlayer.resume()
                    } catch {
                        do {
                            try await ttsPlayer.play(text, languageCode: viewModel.config?.targetLanguage.rawValue ?? InputLanguage.english.rawValue)
                        } catch {
                            logError("[StoryLabReadingView] Failed to play story audio: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Navigation Section

    @ViewBuilder
    private func navigationSection(session: StorySession, totalPages: Int) -> some View {
        if session.story.pages.count > 1 {
            HStack(spacing: 16) {
                ActionButton(
                    Loc.StoryLab.Reading.previousPage,
                    style: .bordered
                ) {
                    viewModel.handle(.previousPage)
                    ttsPlayer.stop()
                }
                .disabled(!viewModel.canNavigatePrevious)

                if session.currentPageIndex == totalPages - 1 {
                    ActionButton(
                        Loc.StoryLab.Quiz.finishStory,
                        style: .borderedProminent
                    ) {
                        if viewModel.isCurrentPageQuizComplete {
                            viewModel.handle(.finishStory)
                        }
                    }
                    .disabled(!viewModel.isCurrentPageQuizComplete)
                } else {
                    ActionButton(
                        Loc.StoryLab.Reading.nextPage,
                        style: .borderedProminent
                    ) {
                        viewModel.handle(.nextPage)
                        ttsPlayer.stop()
                    }
                    .disabled(!viewModel.canNavigateNext || !viewModel.isCurrentPageQuizComplete)
                }
            }
            .padding(.top, 8)
        }
    }
}
