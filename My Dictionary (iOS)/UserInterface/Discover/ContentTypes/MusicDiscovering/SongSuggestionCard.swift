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
                .overlay(alignment: .topTrailing) {
                    // Service badge
                    serviceBadge
                }
                
                VStack(alignment: .leading, spacing: 4) {
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
                    
                    if let album = song.album {
                        Text(album)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: 140, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
    
    private var serviceBadge: some View {
        Group {
            switch song.serviceType {
            case .appleMusic:
                Image(systemName: "apple.logo")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            case .spotify:
                Text("S")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.green.opacity(0.8))
                    .clipShape(Circle())
            }
        }
        .padding(4)
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
                serviceType: .appleMusic,
                serviceId: "1"
            ),
            onTap: {}
        )
    }
    .padding()
}

