//
//  WordListCellView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/21/25.
//

import SwiftUI

struct WordListCellView: View {
    @StateObject private var word: CDWord

    init(word: CDWord) {
        self._word = StateObject(wrappedValue: word)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(word.wordItself ?? "")
                .bold()
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 4) {
                if word.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
                
                Text(word.partOfSpeech ?? "")
                    .foregroundStyle(.secondary)

                // Difficulty label
                if word.shouldShowDifficultyLabel {
                    Text(word.difficultyLabel)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(word.difficultyColor.opacity(0.2))
                        .foregroundStyle(word.difficultyColor)
                        .clipShape(Capsule())
                }
                
                if let languageCode = word.languageCode {
                    Text(languageCode.uppercased())
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(vertical: 4, horizontal: 8)
    }
}
