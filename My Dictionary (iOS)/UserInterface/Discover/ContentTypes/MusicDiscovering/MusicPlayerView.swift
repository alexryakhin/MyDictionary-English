//
//  MusicPlayerView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct MusicPlayerView: View {
    let song: Song
    let lyrics: SongLyrics?
    @ObservedObject var viewModel: MusicDiscoveringViewModel
    @StateObject private var musicPlayer = MusicPlayerService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingExplanation = false
    @State private var showingQuiz = false
    @State private var showingVocabulary = false
    @State private var showingPreListen = false
    @State private var showingDeepDive = false
    @State private var showingPractice = false
    @State private var currentStage: LearningStage = .preListen
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 5-Stage Progress Indicator
                learningStagesIndicator
                
                // Album Artwork
                albumArtworkView

                // Song Info
                songInfoView

                // Progress Slider
                progressSlider

                // Controls
                playbackControls
                
                // Stage-specific content
                stageContent

                // AI Features Section
                aiFeaturesSection
            }
            .padding()
        }
        .sheet(isPresented: $showingExplanation) {
            if let aiContent = viewModel.aiContent {
                AIExplanationView(
                    explanations: aiContent.explanations,
                    culturalContext: aiContent.culturalContext
                )
            }
        }
        .sheet(isPresented: $showingQuiz) {
            if let aiContent = viewModel.aiContent,
               let quiz = aiContent.quiz {
                MusicQuizView(quiz: quiz, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingVocabulary) {
            if let aiContent = viewModel.aiContent {
                VocabularyWordsView(
                    vocabularyWords: aiContent.vocabularyWords,
                    song: song
                )
            }
        }
        .sheet(isPresented: $showingPreListen) {
            if let hook = viewModel.preListenHook {
                PreListenView(hook: hook, song: song)
            }
        }
        .sheet(isPresented: $showingDeepDive) {
            if let adaptedLesson = getAdaptedLesson() {
                DeepDiveCardsView(lesson: adaptedLesson)
            }
        }
        .sheet(isPresented: $showingPractice) {
            if let lyrics = lyrics {
                PracticeView(song: song, lyrics: lyrics, viewModel: viewModel)
            }
        }
        .onAppear {
            // Generate pre-listen hook on appear
            if viewModel.preListenHook == nil && lyrics?.hasLyrics == true {
                Task {
                    await viewModel.generatePreListenHook()
                }
            }
        }
    }
    
    // MARK: - Learning Stages Indicator
    
    private var learningStagesIndicator: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(LearningStage.allCases) { stage in
                    Button(action: {
                        currentStage = stage
                    }) {
                        StageIndicator(
                            stage: stage,
                            isActive: currentStage == stage,
                            isCompleted: isStageCompleted(stage)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text(currentStage.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func isStageCompleted(_ stage: LearningStage) -> Bool {
        switch stage {
        case .preListen:
            return viewModel.preListenHook != nil
        case .listenRead:
            return musicPlayer.currentTime > 0
        case .deepDive:
            return viewModel.aiContent != nil
        case .practice:
            return false // Will be tracked when practice is implemented
        case .quiz:
            return viewModel.currentSession?.hasCompletedQuiz == true
        }
    }
    
    // MARK: - Stage Content
    
    @ViewBuilder
    private var stageContent: some View {
        switch currentStage {
        case .preListen:
            if let hook = viewModel.preListenHook {
                PreListenView(hook: hook, song: song)
            } else if viewModel.isLoadingPreListenHook {
                ProgressView("Loading pre-listen guide...")
                    .padding()
            } else {
                Button("Generate Pre-Listen Guide") {
                    Task {
                        await viewModel.generatePreListenHook()
                    }
                }
                .padding()
            }
            
        case .listenRead:
            if let lyrics = lyrics {
                lyricsSection(lyrics: lyrics)
            } else {
                lyricsUnavailableView
            }
            
        case .deepDive:
            if let adaptedLesson = getAdaptedLesson() {
                DeepDiveCardsView(lesson: adaptedLesson)
            } else {
                Button("Generate Deep Dive") {
                    Task {
                        await viewModel.generateExplanation()
                    }
                }
                .padding()
            }
            
        case .practice:
            if let lyrics = lyrics {
                PracticeView(song: song, lyrics: lyrics, viewModel: viewModel)
            } else {
                Text("Lyrics needed for practice")
                    .foregroundColor(.secondary)
                    .padding()
            }
            
        case .quiz:
            if let quiz = viewModel.aiContent?.quiz {
                MusicQuizView(quiz: quiz, viewModel: viewModel)
            } else {
                Button("Generate Quiz") {
                    Task {
                        await viewModel.generateQuiz()
                    }
                }
                .padding()
            }
        }
    }
    
    private func getAdaptedLesson() -> AdaptedLesson? {
        // Get adapted lesson from viewModel
        return viewModel.adaptedLesson
    }
    
    // MARK: - Album Artwork
    
    private var albumArtworkView: some View {
        AsyncImage(url: song.albumArtURL) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.4), .purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                )
        }
        .frame(width: 300, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
    }
    
    // MARK: - Song Info
    
    private var songInfoView: some View {
        VStack(spacing: 8) {
            Text(song.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(song.artist)
                .font(.title3)
                .foregroundColor(.secondary)
            
            if let album = song.album {
                Text(album)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Progress Slider
    
    private var progressSlider: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { musicPlayer.currentTime },
                    set: { musicPlayer.seek(to: $0) }
                ),
                in: 0...max(musicPlayer.duration, 1),
                onEditingChanged: { editing in
                    if editing {
                        // User started dragging
                        musicPlayer.startSeeking()
                    } else {
                        // User finished dragging
                        musicPlayer.finishSeeking(to: musicPlayer.currentTime)
                    }
                }
            )
            
            HStack {
                Text(formatTime(musicPlayer.currentTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatTime(musicPlayer.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Playback Controls
    
    private var playbackControls: some View {
        HStack(spacing: 40) {
            Button(action: {
                Task {
                    do {
                        try await musicPlayer.skipToPrevious()
                        // Reload lyrics for the new song
                        await viewModel.updateLyricsForCurrentSong()
                    } catch {
                        // If error, just seek to beginning
                        musicPlayer.seek(to: 0)
                    }
                }
            }) {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Button(action: {
                viewModel.playPause()
            }) {
                Image(systemName: musicPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.primary)
            }
            
            Button(action: {
                Task {
                    do {
                        try await musicPlayer.skipToNext()
                        // Reload lyrics for the new song
                        await viewModel.updateLyricsForCurrentSong()
                    } catch {
                        // If no next song, just stop
                        musicPlayer.stop()
                    }
                }
            }) {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - Lyrics Section
    
    private func lyricsSection(lyrics: SongLyrics) -> some View {
        CustomSectionView(header: "Lyrics") {
            EnhancedLyricsView(
                lyrics: lyrics,
                currentTime: musicPlayer.currentTime,
                viewModel: viewModel
            )
        }
    }
    
    private var lyricsUnavailableView: some View {
        CustomSectionView(header: "Lyrics") {
            VStack(spacing: 12) {
                Image(systemName: "music.note.text")
                    .font(.title)
                    .foregroundColor(.secondary)
                
                Text("Lyrics not available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - AI Features Section
    
    private var aiFeaturesSection: some View {
        CustomSectionView(header: "AI Learning Features") {
            VStack(spacing: 12) {
                // Get Explanation Button
                Button(action: {
                    if viewModel.aiContent == nil {
                        Task {
                            await viewModel.generateExplanation()
                            showingExplanation = true
                        }
                    } else {
                        showingExplanation = true
                    }
                }) {
                    HStack {
                        Image(systemName: "text.bubble")
                        Text("Get Explanation")
                        Spacer()
                        if viewModel.isLoadingExplanation {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.secondarySystemGroupedBackground)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isLoadingExplanation)
                
                // Take Quiz Button
                Button(action: {
                    if viewModel.aiContent?.quiz == nil {
                        Task {
                            await viewModel.generateQuiz()
                            showingQuiz = true
                        }
                    } else {
                        showingQuiz = true
                    }
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("Take Quiz")
                        Spacer()
                        if viewModel.isLoadingQuiz {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.secondarySystemGroupedBackground)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isLoadingQuiz)
                
                // Extract Vocabulary Button
                Button(action: {
                    viewModel.extractVocabulary()
                    showingVocabulary = true
                }) {
                    HStack {
                        Image(systemName: "text.magnifyingglass")
                        Text("Extract Vocabulary")
                        Spacer()
                        if viewModel.aiContent?.vocabularyWords.isEmpty != false {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.secondarySystemGroupedBackground)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        MusicPlayerView(
            song: Song(
                id: "1",
                title: "La Vida Es Un Carnaval",
                artist: "Celia Cruz",
                album: "Mi Vida Es Cantar",
                albumArtURL: nil,
                duration: 233,
                previewURL: nil,
                serviceId: "1"
            ),
            lyrics: nil,
            viewModel: MusicDiscoveringViewModel()
        )
    }
}

