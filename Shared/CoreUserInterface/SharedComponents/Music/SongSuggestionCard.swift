//
//  SongSuggestionCard.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct SongSuggestionCard: View {
    let song: Song
    let size: CGSize
    let onTap: () -> Void

    init(song: Song, size: CGSize = .init(width: 140, height: 140), onTap: @escaping () -> Void) {
        self.song = song
        self.size = size
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Album Artwork
                CachedAsyncImage(url: song.albumArtURL) { image in
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
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .label.opacity(0.3), radius: 5)

                VStack(alignment: .leading, spacing: 4) {
                    // CEFR Badge - Show from song
                    if let cefrLevel = song.cefrLevel {
                        HStack(spacing: 4) {
                            TagView(
                                text: cefrLevel.rawValue,
                                color: cefrLevel.color,
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
            .frame(width: size.width, alignment: .topLeading)
        }
        .buttonStyle(.plain)
    }
}
