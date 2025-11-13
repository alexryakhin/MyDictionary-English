//
//  SongLessonResultsDetailView.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 11/12/25.
//

import SwiftUI
import Flow

struct SongLessonResultsDetailView: View {
    @Environment(\.openWindow) private var openWindow

    private let song: Song

    @State private var session: MusicDiscoveringSession
    @State private var totalQuestions: Int = 0
    @State private var totalListeningSeconds: TimeInterval = 0
    @State private var isFavorite: Bool = false
    @State private var isOpeningLesson = false

    init(session: MusicDiscoveringSession, song: Song) {
        _session = State(initialValue: session)
        self.song = song
    }
    
    private var accuracy: Int {
        guard !session.quizAnswers.isEmpty else { return 0 }
        let correct = session.quizAnswers.filter { $0.isCorrect }.count
        return Int((Double(correct) / Double(session.quizAnswers.count)) * 100)
    }
    
    private var formattedListeningTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .short
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: totalListeningSeconds) ?? "0s"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                statsSection
                if !session.discoveredWords.isEmpty {
                    discoveredWordsSection
                }
                actionSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .groupedBackgroundWithConfetti(isActive: .constant(accuracy >= 80))
        .task {
            await loadLatestSession()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                if let artworkURL = song.albumArtURL {
                    CachedAsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.secondarySystemGroupedBackground)
                    }
                    .frame(width: 100, height: 100)
                    .cornerRadius(12)
                    .shadow(color: .label.opacity(0.25), radius: 4, x: 0, y: 2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.title3.weight(.semibold))
                    
                    Text(song.artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let level = song.cefrLevel {
                        TagView(text: level.displayName, size: .mini)
                    }
                }
                
                Spacer()
            }
            
            Divider()

            Text(Loc.MusicDiscovering.Results.Header.title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(Loc.MusicDiscovering.Results.Header.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var statsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
            statCard(
                title: Loc.MusicDiscovering.Results.Stats.accuracy,
                value: "\(accuracy)%",
                icon: "percent",
                color: .green
            )

            statCard(
                title: Loc.MusicDiscovering.Results.Stats.questions,
                value: "\(session.quizAnswers.filter { $0.isCorrect }.count)/\(totalQuestions)",
                icon: "checkmark.circle",
                color: .blue
            )

            statCard(
                title: Loc.MusicDiscovering.Results.Stats.newWords,
                value: "\(session.discoveredWords.count)",
                icon: "book",
                color: .purple
            )

            statCard(
                title: Loc.MusicDiscovering.Results.Stats.time,
                value: formattedListeningTime,
                icon: "clock",
                color: .orange
            )
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .clippedWithPaddingAndBackground(
            Color.secondarySystemGroupedBackground,
            in: .rect(cornerRadius: 16)
        )
    }
    
    private var discoveredWordsSection: some View {
        CustomSectionView(header: Loc.MusicDiscovering.Results.DiscoveredWords.title) {
            HFlow(alignment: .top, spacing: 8) {
                ForEach(session.discoveredWords.sorted(), id: \.self) { word in
                    Text(word)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ActionButton(
                Loc.MusicDiscovering.Sheet.Cta.startLesson,
                systemImage: "arrow.uturn.backward",
                style: .bordered
            ) {
                openLessonWindow()
            }
            .disabled(isOpeningLesson)

            ActionButton(
                isFavorite ? Loc.MusicDiscovering.Results.Actions.removeFromFavorites : Loc.MusicDiscovering.Results.Actions.addToFavorites,
                systemImage: isFavorite ? "heart.fill" : "heart",
                style: .bordered
            ) {
                toggleFavorite()
            }

            ActionButton(
                Loc.MusicDiscovering.Results.Actions.backToDiscover,
                style: .borderedProminent
            ) {
                SideBarManager.shared.discoverDetail = .music(.overview)
            }
        }
    }
    
    private func toggleFavorite() {
        do {
            try SongLessonSessionService.shared.toggleFavorite(song: song)
            isFavorite.toggle()
        } catch {
            AlertCenter.shared.showAlert(with: .init(
                title: isFavorite ? Loc.MusicDiscovering.Results.Actions.removeFromFavorites : Loc.MusicDiscovering.Results.Actions.addToFavorites,
                message: error.localizedDescription,
                actionText: Loc.Actions.ok
            ))
        }
    }
    
    private func openLessonWindow() {
        guard !isOpeningLesson else { return }
        isOpeningLesson = true
        
        Task {
            do {
                let lessonService = MusicLessonService.shared
                let lyrics: SongLyrics
                if let cached = await lessonService.getCachedHookPackage(for: song.id) {
                    lyrics = cached.lyrics
                } else {
                    lyrics = try await LRCLibService.shared.getLyrics(
                        trackName: song.title,
                        artistName: song.artist,
                        albumName: song.album,
                        duration: song.duration
                    )
                }
                let config = MusicPlayerConfig(song: song, lyrics: lyrics)
                await MainActor.run {
                    openWindow(id: WindowID.musicLesson, value: config)
                }
            } catch {
                await MainActor.run {
                    presentLessonOpenError(error)
                }
            }
            
            await MainActor.run {
                isOpeningLesson = false
            }
        }
    }
    
    private func presentLessonOpenError(_ error: Error) {
        let message: String
        if let musicError = error as? MusicError {
            message = musicError.localizedDescription
        } else {
            message = error.localizedDescription
        }
        
        AlertCenter.shared.showAlert(
            with: .init(
                title: Loc.MusicDiscovering.Player.Lesson.failed,
                message: message,
                actionText: Loc.Actions.ok
            )
        )
    }
    
    private func loadLatestSession() async {
        if let stored = SongLessonSessionService.shared.getSession(by: session.id),
           let updated = stored.toMusicDiscoveringSession(),
           let lesson = stored.lesson {
            await MainActor.run {
                session = updated
                totalListeningSeconds = session.totalListeningTime
                totalQuestions = Int(stored.totalQuestions)
                isFavorite = stored.isFavorite
                
                if totalQuestions == 0 {
                    let fillCount = lesson.quiz.fillInBlanks.count
                    let mcqCount = lesson.quiz.meaningMCQ.count
                    totalQuestions = fillCount + mcqCount
                }
            }
        } else {
            await MainActor.run {
                totalListeningSeconds = session.totalListeningTime
                totalQuestions = max(session.quizAnswers.count, totalQuestions)
            }
        }
    }
}

