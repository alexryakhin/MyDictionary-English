//
//  WordCollectionPreviewCard.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 1/27/25.
//

import SwiftUI

struct WordCollectionPreviewCard: View {
    let collection: WordCollection
    @StateObject private var navigationManager: NavigationManager = .shared
    
    var body: some View {
        Button {
            handleCollectionTap()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Collection image placeholder
                AsyncImage(
                    url: collection.imageURL,
                    content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    },
                    placeholder: {
                        if let imageName = collection.localImageName {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
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
    
    private func handleCollectionTap() {
        // Check if this is a premium collection and user doesn't have premium access
        if collection.isPremium && !SubscriptionService.shared.isProUser {
            PaywallService.shared.presentPaywall(for: .wordCollections) { didSubscribe in
                if didSubscribe {
                    // User subscribed, now allow navigation to collection details
                    navigationManager.navigationPath.append(NavigationDestination.wordCollectionDetails(collection))
                }
                // If user didn't subscribe, don't navigate - they stay on the collections list
            }
        } else {
            // Free collection or user has premium access - allow navigation
            navigationManager.navigationPath.append(NavigationDestination.wordCollectionDetails(collection))
        }
    }
}

struct WordCollectionGridPreviewCard: View {
    let collection: WordCollection
    @StateObject private var navigationManager: NavigationManager = .shared

    var body: some View {
        Button {
            handleCollectionTap()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Collection image placeholder
                GeometryReader { geo in
                    AsyncImage(
                        url: collection.imageURL,
                        content: { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        },
                        placeholder: {
                            if let imageName = collection.localImageName {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
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
    
    private func handleCollectionTap() {
        // Check if this is a premium collection and user doesn't have premium access
        if collection.isPremium && !SubscriptionService.shared.isProUser {
            PaywallService.shared.presentPaywall(for: .wordCollections) { didSubscribe in
                if didSubscribe {
                    // User subscribed, now allow navigation to collection details
                    navigationManager.navigationPath.append(NavigationDestination.wordCollectionDetails(collection))
                }
                // If user didn't subscribe, don't navigate - they stay on the collections list
            }
        } else {
            // Free collection or user has premium access - allow navigation
            navigationManager.navigationPath.append(NavigationDestination.wordCollectionDetails(collection))
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
