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
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.wordItself)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(word.definition)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    // Favorite status removed - using simple word display

                    if let phonetic = word.phonetic, !phonetic.isEmpty {
                        Text("[\(phonetic)]")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack {
                Text(word.partOfSpeech)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accent.opacity(0.2))
                    .foregroundStyle(.accent)
                    .clipShape(Capsule())

                if shouldShowLanguageLabel {
                    Text(languageDisplayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())
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

                Spacer()

                Text(word.addedByShortText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            // Add collaborator info below
            Text(word.addedByDisplayText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
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
