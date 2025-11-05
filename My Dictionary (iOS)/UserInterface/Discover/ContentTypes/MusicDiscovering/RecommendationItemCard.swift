//
//  RecommendationItemCard.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct RecommendationItemCard: View {
    let item: RecommendationItem
    let songTag: SongTag?
    let generationCount: Int?
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Artwork
            AsyncImage(url: artworkURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.2))
                    .overlay {
                        Image(systemName: iconName)
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                    }
            }
            .frame(width: 160, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Title
            Text(item.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // Subtitle
            Text(item.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            // Type Badge
            HStack(spacing: 4) {
                Image(systemName: typeIcon)
                    .font(.caption2)
                Text(item.type.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(typeColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(typeColor.opacity(0.15))
            )
            
            // CEFR Badge (if song tag available)
            if let tag = songTag {
                Text(tag.cefr)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(cefrColor(for: tag.cefr))
                    )
            }
            
            // Generation Count (if available)
            if let count = generationCount, count > 0 {
                Text("Learned by \(count) others")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Reason (if available)
            if let reason = item.reason {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(width: 160)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondarySystemGroupedBackground)
        )
        .onTapGesture {
            onTap()
        }
    }
    
    // MARK: - Computed Properties
    
    private var artworkURL: URL? {
        guard let urlString = item.artworkURL else { return nil }
        return URL(string: urlString)
    }
    
    private var iconName: String {
        switch item.type {
        case .artist:
            return "person.fill"
        case .album:
            return "square.stack.fill"
        case .song:
            return "music.note"
        }
    }
    
    private var typeIcon: String {
        switch item.type {
        case .artist:
            return "person.crop.circle.fill"
        case .album:
            return "square.stack.3d.up.fill"
        case .song:
            return "music.note.list"
        }
    }
    
    private var typeColor: Color {
        switch item.type {
        case .artist:
            return .purple
        case .album:
            return .blue
        case .song:
            return .green
        }
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

