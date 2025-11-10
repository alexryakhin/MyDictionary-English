//
//  SongSuggestionCard.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct SongSuggestionCard: View {
    let song: Song
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
                .shadow(color: .label.opacity(0.3), radius: 5)

                VStack(alignment: .leading, spacing: 4) {
                    // CEFR Badge - Show from song
                    if let cefrLevel = song.cefrLevel {
                        HStack(spacing: 4) {
                            TagView(
                                text: cefrLevel.rawValue,
                                color: cefrColor(for: cefrLevel.rawValue),
                                size: .mini
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
