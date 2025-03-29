//
//  WordsListCellView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/21/25.
//

import SwiftUI

struct WordsListCellView: View {
    var model: Model

    var body: some View {
        HStack(spacing: 8) {
            Text(model.word)
                .bold()
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if model.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            Text(model.partOfSpeech)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    struct Model {
        let word: String
        let partOfSpeech: String
        let isFavorite: Bool
        let isSelected: Bool
    }
}
