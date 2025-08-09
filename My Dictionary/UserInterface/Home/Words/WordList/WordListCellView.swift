//
//  WordListCellView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/21/25.
//

import SwiftUI

struct WordListCellView: View {

    @StateObject var word: CDWord

    init(word: CDWord) {
        self._word = StateObject(wrappedValue: word)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(word.wordItself ?? "")
                    .bold()
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if word.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }

                // Difficulty label
                if word.shouldShowDifficultyLabel {
                    Image(systemName: word.difficulty.imageName)
                        .font(.caption)
                        .foregroundStyle(word.difficulty.color)
                }

                Text(word.partOfSpeechDecoded.rawValue)
                    .foregroundColor(.secondary)

                // Language label
                if word.shouldShowLanguageLabel, let code = word.languageCode {
                    Text(code.uppercased())
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .frame(sideLength: 12)
                    .foregroundColor(.secondary)
            }
            
            // Tags
            if !word.tagsArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(word.tagsArray, id: \.id) { tag in
                            Text(tag.name ?? "")
                                .font(.caption2)
                                .padding(vertical: 2, horizontal: 4)
                                .background(tag.colorValue.color.opacity(0.2))
                                .foregroundStyle(tag.colorValue.color)
                                .clipShape(Capsule())
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
        .padding(vertical: 12, horizontal: 16)
        .background(Color(.secondarySystemGroupedBackground))
    }
}
