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
                Text(word.partOfSpeechDecoded.rawValue)
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.right")
                    .frame(sideLength: 12)
                    .foregroundColor(.secondary)
            }
            
            // Tags
            if !word.tagsArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(word.tagsArray, id: \.id) { tag in
                            TagChip(tag: tag) {
                                // No action needed for read-only display
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}
