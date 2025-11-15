//
//  SongLessonResultsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI
import Flow

struct SongLessonSharePreviewData: Identifiable {
    let id = UUID()
    let song: Song
    let accuracy: Int
    let correctAnswers: Int
    let totalQuestions: Int
    let discoveredWordsCount: Int
    let formattedListeningTime: String
    let cefrLevel: CEFRLevel?
}

struct SongLessonResultsView: View {
    @StateObject private var viewModel: SongLessonResultsViewModel
    @State private var sharePreviewData: SongLessonSharePreviewData?

    init(session: MusicDiscoveringSession, song: Song) {
        _viewModel = StateObject(wrappedValue: SongLessonResultsViewModel(session: session))
        _ = song
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Celebration header
                celebrationHeader
                
                // Song info
                songInfo
                
                // Stats grid
                statsGrid
                
                // Discovered words
                if viewModel.discoveredWordsCount > 0 {
                    discoveredWordsSection
                }
                
                // Actions
                actionsSection
            }
            .padding(vertical: 12, horizontal: 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .groupedBackgroundWithConfetti(isActive: .constant(viewModel.accuracy >= 80))
        .navigation(
            title: Loc.MusicDiscovering.Results.Navigation.title,
            mode: .regular,
            showsBackButton: true,
            trailingContent: {
                HeaderButton(Loc.Actions.done) {
                    NavigationManager.shared.popToRoot()
                }
            }
        )
        .overlay {
            if viewModel.showStreakAnimation, let streak = viewModel.currentDayStreak {
                StreakProgressionAnimation(
                    isActive: Binding(
                        get: { viewModel.showStreakAnimation },
                        set: { viewModel.setStreakAnimationActive($0) }
                    ),
                    targetStreak: streak
                )
            }
        }
        .sheet(item: $sharePreviewData) { data in
            SongLessonSharePreviewView(data: data)
        }
    }
    
    // MARK: - Celebration Header
    
    private var celebrationHeader: some View {
        VStack(spacing: 16) {
            // Confetti or success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text(Loc.MusicDiscovering.Results.Header.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(Loc.MusicDiscovering.Results.Header.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Song Info

    @ViewBuilder
    private var songInfo: some View {
        let song = viewModel.session.song
        HStack(spacing: 16) {
            // Artwork
            if let artworkURL = song.albumArtURL {
                CachedAsyncImage(url: artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.secondarySystemGroupedBackground)
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                .shadow(color: .label.opacity(0.3), radius: 3)
            }
            
            // Song details
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .clippedWithPaddingAndBackground(in: .rect(cornerRadius: 16))
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2),
            spacing: 16
        ) {
            statCard(
                title: Loc.MusicDiscovering.Results.Stats.accuracy,
                value: "\(viewModel.accuracy)%",
                icon: "percent",
                color: .green
            )
            
            statCard(
                title: Loc.MusicDiscovering.Results.Stats.questions,
                value: "\(viewModel.correctAnswers)/\(viewModel.totalQuestions)",
                icon: "checkmark.circle",
                color: .blue
            )
            
            statCard(
                title: Loc.MusicDiscovering.Results.Stats.newWords,
                value: "\(viewModel.discoveredWordsCount)",
                icon: "book",
                color: .purple
            )
            
            statCard(
                title: Loc.MusicDiscovering.Results.Stats.time,
                value: viewModel.formattedListeningTime,
                icon: "clock",
                color: .orange
            )
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(.largeTitle, design: .rounded, weight: .medium))
                .foregroundStyle(color)

            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)

            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clippedWithPaddingAndBackground(in: .rect(cornerRadius: 16))
    }
    
    // MARK: - Discovered Words Section

    @ViewBuilder
    private var discoveredWordsSection: some View {
        let sessionWords = viewModel.session.discoveredWords
        VStack(alignment: .leading, spacing: 12) {
            Text(Loc.MusicDiscovering.Results.DiscoveredWords.title)
                .font(.headline)
            
            HFlow(alignment: .top, spacing: 8) {
                ForEach(Array(sessionWords.sorted()), id: \.self) { word in
                    Text(word)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundColor(.accentColor)
                        .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clippedWithPaddingAndBackground(in: .rect(cornerRadius: 16))
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Share button
            ActionButton(
                Loc.MusicDiscovering.Results.Actions.share,
                systemImage: "square.and.arrow.up",
                style: .bordered
            ) {
                let session = viewModel.session
                sharePreviewData = SongLessonSharePreviewData(
                    song: session.song,
                    accuracy: viewModel.accuracy,
                    correctAnswers: viewModel.correctAnswers,
                    totalQuestions: viewModel.totalQuestions,
                    discoveredWordsCount: viewModel.discoveredWordsCount,
                    formattedListeningTime: viewModel.formattedListeningTime,
                    cefrLevel: session.song.cefrLevel
                )
            }
            
            // Favorite button
            ActionButton(
                viewModel.isFavorite ? Loc.MusicDiscovering.Results.Actions.removeFromFavorites : Loc.MusicDiscovering.Results.Actions.addToFavorites,
                systemImage: viewModel.isFavorite ? "heart.fill" : "heart",
                style: .bordered
            ) {
                viewModel.toggleFavorite()
            }
            
            // Close button
            ActionButton(
                Loc.MusicDiscovering.Results.Actions.backToDiscover,
                style: .borderedProminent
            ) {
                NavigationManager.shared.popToRoot()
            }
        }
    }
}

// MARK: - Activity View Controller

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
