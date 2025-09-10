//
//  WordCollectionPreviewCard.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/27/25.
//

import SwiftUI

struct WordCollectionPreviewCard: View {
    let collection: WordCollection
    @StateObject private var navigationManager: NavigationManager = .shared
    
    var body: some View {
        Button {
            navigationManager.navigationPath.append(NavigationDestination.wordCollectionDetails(collection))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Collection image placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 80)
                    .overlay(
                        VStack {
                            Image(systemName: "book.closed.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            if collection.isPremium {
                                Image(systemName: "crown.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(collection.wordCountText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(collection.level.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(levelColor(for: collection.level).opacity(0.2))
                        .foregroundColor(levelColor(for: collection.level))
                        .cornerRadius(4)
                }
            }
            .frame(width: 120)
        }
        .buttonStyle(.plain)
    }
    
    private func levelColor(for level: WordLevel) -> Color {
        switch level {
        case .a1, .a2:
            return .green
        case .b1, .b2:
            return .orange
        case .c1, .c2:
            return .red
        }
    }
}

#Preview {
    WordCollectionPreviewCard(collection: WordCollection(
        title: "Business English",
        words: [],
        level: .b2,
        tagValue: "Business",
        languageCode: "en"
    ))
}
