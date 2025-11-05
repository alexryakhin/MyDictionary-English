//
//  SongSuggestionCard.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct SongSuggestionCard: View {
    let song: Song
    let songTag: SongTag?
    let generationCount: Int?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Album Artwork
                AsyncImage(url: song.albumArtURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    // CEFR Badge
                    if let cefr = songTag?.cefr {
                        HStack(spacing: 4) {
                            Text(cefr)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(cefrColor(for: cefr))
                                )
                            
                            Spacer()
                        }
                    }
                    
                    Text(song.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                    
                    Text(song.artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    // Themes (if available)
                    if let themes = songTag?.themes, !themes.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(themes.prefix(2)), id: \.self) { theme in
                                Text(theme)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.secondary.opacity(0.1))
                                    )
                            }
                        }
                    }
                    
                    // Generation count (if available)
                    if let count = generationCount, count > 0 {
                        Text("Already learned by \(count) others")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .frame(width: 140, alignment: .topLeading)
        }
        .buttonStyle(.plain)
    }
    
    private func cefrColor(for level: String) -> Color {
        switch level {
        case "A1", "A2":
            return .green
        case "B1", "B2":
            return .blue
        case "C1", "C2":
            return .purple
        default:
            return .gray
        }
    }
}

#Preview {
    HStack {
        SongSuggestionCard(
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
            songTag: SongTag(
                id: "1",
                cefr: "B1",
                vocabCEFR: [:],
                grammarPoints: ["presente"],
                themes: ["love", "celebration"],
                embeddings: [],
                difficultyScore: 0.68
            ),
            generationCount: 124,
            onTap: {}
        )
    }
    .padding()
}

