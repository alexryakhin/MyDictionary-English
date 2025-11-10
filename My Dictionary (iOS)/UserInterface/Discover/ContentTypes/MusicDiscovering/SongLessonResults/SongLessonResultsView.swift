//
//  SongLessonResultsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct SongLessonResultsConfig: Hashable {
    let session: MusicDiscoveringSession
    let song: Song
    
    static func == (lhs: SongLessonResultsConfig, rhs: SongLessonResultsConfig) -> Bool {
        return lhs.session.id == rhs.session.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(session.id)
    }
}

struct SongLessonResultsView: View {
    let session: MusicDiscoveringSession
    let song: Song
    
    @StateObject private var viewModel = SongLessonResultsViewModel()

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
        }
        .groupedBackgroundWithConfetti(isActive: .constant(viewModel.accuracy >= 80))
        .navigation(
            title: "Lesson Complete",
            mode: .regular,
            showsBackButton: true,
            trailingContent: {
                HeaderButton(Loc.Actions.done) {
                    NavigationManager.shared.popToRoot()
                }
            }
        )
        .sheet(isPresented: $viewModel.showShareSheet) {
            ActivityViewController(activityItems: [viewModel.shareText])
        }
        .task {
            viewModel.handle(.loadResults(session))
        }
    }
    
    // MARK: - Celebration Header
    
    private var celebrationHeader: some View {
        VStack(spacing: 16) {
            // Confetti or success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Great Job!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("You've completed the lesson")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Song Info
    
    private var songInfo: some View {
        HStack(spacing: 16) {
            // Artwork
            if let artworkURL = song.albumArtURL {
                AsyncImage(url: artworkURL) { image in
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
                title: "Accuracy",
                value: "\(viewModel.accuracy)%",
                icon: "percent",
                color: .green
            )
            
            statCard(
                title: "Questions",
                value: "\(viewModel.correctAnswers)/\(viewModel.totalQuestions)",
                icon: "checkmark.circle",
                color: .blue
            )
            
            statCard(
                title: "New Words",
                value: "\(viewModel.discoveredWordsCount)",
                icon: "book",
                color: .purple
            )
            
            statCard(
                title: "Time",
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
    
    private var discoveredWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Discovered Words")
                .font(.headline)
            
            if let sessionWords = viewModel.session?.discoveredWords {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100))
                ], spacing: 8) {
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
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Share button
            ActionButton(
                "Share Results",
                systemImage: "square.and.arrow.up",
                style: .bordered
            ) {
                viewModel.handle(.shareResults)
            }
            
            // Favorite button
            ActionButton(
                viewModel.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                systemImage: viewModel.isFavorite ? "heart.fill" : "heart",
                style: .bordered
            ) {
                viewModel.handle(.toggleFavorite)
            }
            
            // Close button
            ActionButton(
                "Back to Discover",
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
