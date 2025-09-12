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
                AsyncImage(
                    url: URL(string: "https://plus.unsplash.com/premium_photo-1666739032615-ecbd14dfb543?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8ZW5nbGlzaHxlbnwwfHwwfHx8MA%3D%3D"),
                    content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    },
                    placeholder: {
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
                                Image(systemName: "book.closed.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            )
                    }
                )
                .overlay(alignment: .topTrailing) {
                    if collection.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .padding(12)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(collection.wordCountText)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    TagView(
                        text: collection.level.displayName,
                        color: collection.level.color,
                        size: .small
                    )
                }
            }
            .frame(maxWidth: 120, maxHeight: .infinity, alignment: .top)
        }
        .buttonStyle(.plain)
    }
}

struct WordCollectionGridPreviewCard: View {
    let collection: WordCollection
    @StateObject private var navigationManager: NavigationManager = .shared

    var body: some View {
        Button {
            navigationManager.navigationPath.append(NavigationDestination.wordCollectionDetails(collection))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Collection image placeholder
                GeometryReader { geo in
                    AsyncImage(
                        url: URL(string: "https://plus.unsplash.com/premium_photo-1666739032615-ecbd14dfb543?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8ZW5nbGlzaHxlbnwwfHwwfHx8MA%3D%3D"),
                        content: { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        },
                        placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: geo.size.width, height: geo.size.height)
                                .overlay(
                                    Image(systemName: "book.closed.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                )
                        }
                    )
                }
                .aspectRatio(4/3, contentMode: .fit)
                .overlay(alignment: .topTrailing) {
                    if collection.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .padding(12)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(collection.wordCountText)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    TagView(
                        text: collection.level.displayName,
                        color: collection.level.color,
                        size: .small
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .buttonStyle(.plain)
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
