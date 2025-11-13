//
//  StoryLabReadingView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct StoryLabReadingView: View {
    let config: StoryLabConfig
    let isPresentedModally: Bool
    @StateObject private var viewModel: StoryLabViewModel
    @StateObject private var ttsPlayer = TTSPlayer.shared
    @Environment(\.dismiss) private var dismiss

    @State private var discoveredWord: InteractiveText.SelectedWord?

    init(config: StoryLabConfig, isPresentedModally: Bool) {
        self.config = config
        self.isPresentedModally = isPresentedModally
        self._viewModel = StateObject(wrappedValue: StoryLabViewModel(config: config))
    }

    var body: some View {
        if case .ready(let session) = viewModel.loadingStatus {
            readingContentView(story: session.story, session: session)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 24) {
            AICircularProgressAnimation()
                .frame(maxWidth: 300)

            Text(Loc.StoryLab.Configuration.generating)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(Loc.StoryLab.Configuration.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .groupedBackground()
    }

    // MARK: - Reading Content View

    private func readingContentView(story: AIStoryResponse, session: StorySession) -> some View {
        ScrollViewWithCustomNavBar {
            VStack(spacing: 16) {
                // Page indicator
                HStack {
                    Text(Loc.StoryLab.Reading.page(session.currentPageIndex + 1, story.pages.count))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                
                // Story Content
                storyContentSection(session: session)

                // Quiz Section
                if let currentPage = viewModel.currentPage {
                    StoryLabQuizView(
                        page: currentPage,
                        pageIndex: session.currentPageIndex,
                        viewModel: viewModel
                    )
                }

                // Navigation
                navigationSection(session: session)
            }
            .padding(16)
        } navigationBar: {
            NavigationBarView(
                title: story.title,
                showsDismissButton: isPresentedModally
            )
        }
        .groupedBackground()
        .sheet(item: $discoveredWord) { word in
            let config = AddWordConfig(
                input: word.text,
                inputLanguage: config.targetLanguage,
                selectedDictionaryId: nil,
                isWord: true
            )
            AddWordView(config: config)
                .onDisappear {
                    // Word was saved if sheet dismissed normally
                    // Call handler to attach word to story
                    if let savedWord = discoveredWord?.text {
                        viewModel.onWordSaved?(savedWord)
                    }
                }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Story Content Section

    private func storyContentSection(session: StorySession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Story text with highlighting
            if let currentPage = viewModel.currentPage {
                HighlightedStoryText(
                    text: currentPage.storyText,
                    font: .body,
                    currentChunk: ttsPlayer.currentPlayingChunk,
                    sourceLanguageCode: config.targetLanguage.rawValue
                )
                .onDisappear {
                    // Stop playback when navigating to different page or exiting
                    ttsPlayer.stop()
                }
            }

            // Play button for audio narration
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
                    // Pause playback but keep state for resume
                    ttsPlayer.pause()
                } else {
                    do {
                        // Resume if paused, otherwise start new
                        try await ttsPlayer.resume()
                    } catch {
                        // If resume fails (not paused), start new playback
                        do {
                            try await ttsPlayer.play(text, languageCode: config.targetLanguage.rawValue)
                        } catch {
                            print("Error playing story audio: \(error)")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Navigation Section

    @ViewBuilder
    private func navigationSection(session: StorySession) -> some View {
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

                ActionButton(
                    Loc.StoryLab.Reading.nextPage,
                    style: .borderedProminent
                ) {
                    viewModel.handle(.nextPage)
                    ttsPlayer.stop()
                }
                .disabled(!viewModel.canNavigateNext || !viewModel.isCurrentPageQuizComplete)
            }
            .padding(.top, 8)
        }
    }
}

