//
//  HistoryEntryRow.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct HistoryEntryRow: View {
    let historyEntry: MusicListeningHistory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Album Artwork
                CachedAsyncImage(url: historyEntry.song.albumArtURL) { image in
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
                                .font(.title3)
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Song Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(historyEntry.song.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(historyEntry.song.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(timeAgoText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if historyEntry.completed {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        
                        Text(Loc.MusicDiscovering.History.playCount(historyEntry.playCount))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    private var timeAgoText: String {
        let timeInterval = Date().timeIntervalSince(historyEntry.listenedAt)
        let minutes = Int(timeInterval / 60)
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        
        if days > 0 {
            return Loc.MusicDiscovering.History.Time.days(days)
        } else if hours > 0 {
            return Loc.MusicDiscovering.History.Time.hours(hours)
        } else if minutes > 0 {
            return Loc.MusicDiscovering.History.Time.minutes(minutes)
        } else {
            return Loc.MusicDiscovering.History.Time.justNow
        }
    }
}

#Preview {
    HistoryEntryRow(
        historyEntry: MusicListeningHistory(
            song: Song(
                id: "1",
                title: "La Vida Es Un Carnaval",
                artist: "Celia Cruz",
                album: nil,
                albumArtURL: nil,
                duration: 233,
                serviceId: "1"
            ),
            listeningDuration: 180,
            playCount: 3,
            completed: true
        ),
        onTap: {}
    )
    .padding()
}
