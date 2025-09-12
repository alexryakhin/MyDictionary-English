//
//  WordCollectionItemRow.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 9/12/25.
//

import SwiftUI

struct WordCollectionItemRow: View {
    let word: WordCollectionItem
    let onTap: VoidHandler
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(word.text)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if let phonetics = word.phonetics {
                            Text(phonetics)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    TagView(text: word.partOfSpeech, color: .blue, size: .mini)
                }

                Text(word.definition)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(vertical: 12, horizontal: 16)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
