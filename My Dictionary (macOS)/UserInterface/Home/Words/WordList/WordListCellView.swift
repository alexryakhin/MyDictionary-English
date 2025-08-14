//
//  WordListCellView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/21/25.
//

import SwiftUI

struct WordListCellView: View {

    @StateObject private var word: CDWord
    @StateObject private var sideBarManager = SideBarManager.shared

    private var isSelected: Bool {
        sideBarManager.selectedWord == word
    }

    init(word: CDWord) {
        self._word = StateObject(wrappedValue: word)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(word.wordItself ?? "")
                    .bold()
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if word.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.accent)
                }

                // Difficulty label
                if word.shouldShowDifficultyLabel {
                    Image(systemName: word.difficultyLevel.imageName)
                        .font(.caption)
                        .foregroundStyle(word.difficultyLevel.color)
                }

                Text(word.partOfSpeechDecoded.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Language label
                if word.shouldShowLanguageLabel, let code = word.languageCode {
                    TagView(text: code.uppercased(), color: .blue, size: .mini)
                }

                Image(systemName: "chevron.right")
                    .frame(sideLength: 12)
                    .foregroundStyle(.secondary)
            }
            
            // Tags
            if !word.tagsArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(word.tagsArray, id: \.id) { tag in
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
        .background(isSelected ? Color.accent.opacity(0.1) : Color.secondarySystemGroupedBackground)
    }
}
