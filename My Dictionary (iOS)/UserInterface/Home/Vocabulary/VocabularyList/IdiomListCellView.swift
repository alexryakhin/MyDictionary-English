//
//  IdiomListCellView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/22/25.
//

import SwiftUI

struct IdiomListCellView: View {
    @StateObject private var idiom: CDIdiom

    init(idiom: CDIdiom) {
        self._idiom = StateObject(wrappedValue: idiom)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(idiom.idiomItself ?? "")
                    .bold()
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if idiom.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.accent)
                }

                // Difficulty label
                if idiom.shouldShowDifficultyLabel {
                    Image(systemName: idiom.difficultyLevel.imageName)
                        .font(.caption)
                        .foregroundStyle(idiom.difficultyLevel.color)
                }

                // Language label
                if idiom.shouldShowLanguageLabel, let code = idiom.languageCode {
                    TagView(text: code.uppercased(), color: .blue, size: .mini)
                }

                Image(systemName: "chevron.right")
                    .frame(sideLength: 12)
                    .foregroundStyle(.secondary)
            }

            // Tags
            if !idiom.tagsArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(idiom.tagsArray, id: \.id) { tag in
                            TagView(
                                text: tag.name ?? "",
                                color: tag.colorValue.color,
                                size: .mini
                            )
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
        .padding(vertical: 12, horizontal: 16)
        .background(Color.secondarySystemGroupedBackground)
    }

    struct Model {
        var idiom: String
        var isFavorite: Bool
    }
}
