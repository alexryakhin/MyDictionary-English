//
//  EmptyStateView.swift
//  Suint One
//
//  Created by Aleksandr Riakhin on 9/30/24.
//

import SwiftUI

struct EmptyStateView: View {

    private let imageSystemName: String?
    private let title: String
    private let subtitle: String?
    private let instructions: String?

    init(
        imageSystemName: String? = nil,
        title: String,
        subtitle: String? = nil,
        instructions: String? = nil
    ) {
        self.imageSystemName = imageSystemName
        self.title = title
        self.subtitle = subtitle
        self.instructions = instructions
    }

    var body: some View {
        VStack(spacing: 20) {
            if let imageSystemName {
                Image(systemName: imageSystemName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if let subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)
            }

            if let instructions {
                Text(instructions)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)
            }
        }
        .padding(16)
        .multilineTextAlignment(.center)
    }

    static let nothingFound = Self(
        imageSystemName: "flashlight.off.circle.fill",
        title: "Nothing Found",
        subtitle: "We couldn't find any recipes that match your search.",
        instructions: "Try using different keywords or adjusting your filters."
    )

    static let searchPlaceholder = Self(
        imageSystemName: "magnifyingglass.circle.fill",
        title: "Start searching for recipes",
        instructions: "Try typing an ingredient or dish name to find new recipes."
    )

    static let ingredientsSearchPlaceholder = Self(
        imageSystemName: "magnifyingglass.circle.fill",
        title: "Start searching for ingredients",
        instructions: "Try typing an ingredient name into the search bar."
    )

    static let savedRecipesPlaceholder = Self(
        imageSystemName: "bookmark.circle.fill",
        title: "No Saved Recipes",
        subtitle: "You haven't saved any recipes yet. Save some to get started."
    )
}

#Preview {
    EmptyStateView.nothingFound
}
