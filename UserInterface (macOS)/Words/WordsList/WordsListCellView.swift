//
//  WordsListCellView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/21/25.
//

import SwiftUI

struct WordsListCellView: View {
    var word: Word
    var isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(word.word)
                .bold()
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if word.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .accentColor)
            }
            Text(word.partOfSpeech.rawValue)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
        }
        .padding(vertical: 4, horizontal: 8)
    }
}
