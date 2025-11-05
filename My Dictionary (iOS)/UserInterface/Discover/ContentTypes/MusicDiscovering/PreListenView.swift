//
//  PreListenView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct PreListenView: View {
    let hook: PreListenHook
    let song: Song
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Hook Text
            Text(hook.hook)
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accent.opacity(0.1))
                )
            
            // Target Phrases
            if !hook.targetPhrases.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Focus on these phrases:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(Array(hook.targetPhrases.enumerated()), id: \.offset) { index, phrase in
                        TargetPhraseCard(phrase: phrase)
                    }
                }
            }
            
            // Grammar Highlight
            if let grammar = hook.grammarHighlight {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Grammar Point:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(grammar)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
            }
            
            // Cultural Note
            if let culturalNote = hook.culturalNote {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cultural Context:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(culturalNote)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
            }
        }
        .padding()
    }
}

struct TargetPhraseCard: View {
    let phrase: PreListenHook.TargetPhrase
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // CEFR Badge
            Text(phrase.cefr)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(cefrColor(for: phrase.cefr))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(phrase.phrase)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(phrase.translation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let context = phrase.context, !context.isEmpty {
                    Text(context)
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                        .italic()
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.05))
        )
    }
    
    private func cefrColor(for level: String) -> Color {
        switch level {
        case "A1", "A2":
            return .green
        case "B1", "B2":
            return .blue
        case "C1", "C2":
            return .purple
        default:
            return .gray
        }
    }
}

