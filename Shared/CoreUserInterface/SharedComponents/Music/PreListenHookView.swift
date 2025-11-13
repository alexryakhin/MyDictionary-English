//
//  PreListenHookView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 11/13/25.
//

import SwiftUI

struct PreListenHookView: View {
    let hook: PreListenHook
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Main Hook Text
            Text(hook.hook)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))

            // Target Phrases
            if !hook.targetPhrases.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Loc.MusicDiscovering.Lesson.Phrases.header)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(hook.targetPhrases.indices, id: \.self) { index in
                        let phrase = hook.targetPhrases[index]
                        HStack(alignment: .top, spacing: 8) {
                            TagView(
                                text: phrase.cefr.rawValue,
                                color: phrase.cefr.color,
                                size: .mini
                            )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(phrase.phrase)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if let meaning = phrase.meaning {
                                    Text(meaning)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))
            }
            
            // Grammar Highlight
            if let grammar = hook.grammarHighlight, !grammar.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label(Loc.MusicDiscovering.Sheet.Hook.grammar, systemImage: "book.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(grammar)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))
            }
            
            // Cultural Note
            if let culture = hook.culturalNote, !culture.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label(Loc.MusicDiscovering.Sheet.Hook.culturalNote, systemImage: "globe")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(culture)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))
            }
        }
    }
}
