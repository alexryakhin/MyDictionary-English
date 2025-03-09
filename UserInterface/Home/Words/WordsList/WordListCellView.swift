//
//  WordListCellView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/21/25.
//

import SwiftUI
import CoreUserInterface

struct WordListCellView: ConfigurableView {

    struct Model {
        let word: String
        let isFavorite: Bool
        let partOfSpeech: String
    }

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

            Image(systemName: "chevron.right")
                .frame(sideLength: 12)
                .foregroundColor(.secondary)
        }
    }
}
