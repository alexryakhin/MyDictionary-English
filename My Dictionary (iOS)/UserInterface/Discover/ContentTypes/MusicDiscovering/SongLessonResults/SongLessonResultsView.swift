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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
            .padding()
        }
        .groupedBackground()
        .navigation(
            title: "Lesson Complete",
            mode: .inline,
            trailingContent: {
                HeaderButton(Loc.Actions.done) {
                    dismiss()
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
                .cornerRadius(12)
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
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
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
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
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
                dismiss()
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

#Preview {
    SongLessonResultsView(
        session: MusicDiscoveringSession(
            id: UUID(),
            song: Song(
                id: "1",
                title: "Sample Song",
                artist: "Sample Artist",
                album: "Sample Album",
                albumArtURL: nil,
                duration: 180,
                serviceId: "1"
            ),
            listeningProgress: 180,
            totalListeningTime: 200,
            quizAnswers: [
                MusicDiscoveringSession.QuizAnswer(questionIndex: 0, selectedAnswerIndex: 1, isCorrect: true, answeredAt: Date()),
                MusicDiscoveringSession.QuizAnswer(questionIndex: 1, selectedAnswerIndex: 0, isCorrect: false, answeredAt: Date())
            ],
            discoveredWords: ["test", "words", "here"],
            hasRequestedExplanation: true,
            hasCompletedQuiz: true,
            startedAt: Date(),
            lastPlayedAt: Date()
        ),
        song: Song(
            id: "1",
            title: "Sample Song",
            artist: "Sample Artist",
            album: "Sample Album",
            albumArtURL: nil,
            duration: 180,
            serviceId: "1"
        )
    )
}

