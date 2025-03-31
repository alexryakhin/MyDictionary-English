//
//  WordsListCellView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/21/25.
//

import SwiftUI
import Core

struct WordsListCellView: View {
    var word: Word

    var body: some View {
        HStack(spacing: 8) {
            Text(word.word)
                .bold()
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if word.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            Text(word.partOfSpeech.rawValue)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
