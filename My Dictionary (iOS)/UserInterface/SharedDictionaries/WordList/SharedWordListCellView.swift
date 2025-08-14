//
//  SharedWordListCellView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/1/25.
//

import SwiftUI

struct SharedWordListCellView: View {
    let word: SharedWord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(word.wordItself)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(word.partOfSpeech)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .frame(sideLength: 12)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                if word.difficulties.count > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text(String(format: "%.1f", word.averageDifficulty))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Collaborative features
                if word.likeCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(.red)
                        Text("\(word.likeCount)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if shouldShowLanguageLabel {
                    TagView(text: languageDisplayName, color: .blue, size: .mini)
                }

                Spacer()

                Text(word.addedByShortText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(vertical: 12, horizontal: 16)
        .background(Color.secondarySystemGroupedBackground)
    }

    private var shouldShowLanguageLabel: Bool {
        return !word.languageCode.isEmpty && word.languageCode != "en"
    }

    private var languageDisplayName: String {
        guard let language = Locale.current.localizedString(forLanguageCode: word.languageCode) else {
            return "Unknown"
        }
        return language.capitalized
    }
}
