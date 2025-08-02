//
//  WordsListCellView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/21/25.
//

import SwiftUI

struct WordsListCellView: View {
    var word: CDWord
    var isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(word.wordItself ?? "")
                .bold()
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 4) {
                if word.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white : .accentColor)
                }
                
                Text(word.partOfSpeech ?? "")
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                
                // Difficulty label
                if word.shouldShowDifficultyLabel {
                    Text(word.difficultyLabel)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(word.difficultyColor.opacity(0.2))
                        .foregroundColor(word.difficultyColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(vertical: 4, horizontal: 8)
    }
}
