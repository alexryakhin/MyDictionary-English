//
//  DeepDiveCardsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct DeepDiveCardsView: View {
    let lesson: AdaptedLesson
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Phrase Lab Cards
                if !lesson.phrases.isEmpty {
                    SectionHeader(title: "Phrase Lab", icon: "text.bubble")
                    
                    ForEach(Array(lesson.phrases.enumerated()), id: \.offset) { index, phrase in
                        PhraseLabCard(phrase: phrase)
                    }
                }
                
                // Grammar Nuggets
                if !lesson.grammarNuggets.isEmpty {
                    SectionHeader(title: "Grammar Nuggets", icon: "book")
                    
                    ForEach(Array(lesson.grammarNuggets.enumerated()), id: \.offset) { index, nugget in
                        GrammarNuggetCard(nugget: nugget)
                    }
                }
                
                // Culture Notes
                if !lesson.cultureNotes.isEmpty {
                    SectionHeader(title: "Culture Notes", icon: "globe")
                    
                    ForEach(Array(lesson.cultureNotes.enumerated()), id: \.offset) { index, note in
                        CultureNoteCard(note: note)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accent)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Phrase Lab Card

struct PhraseLabCard: View {
    let phrase: LessonPhrase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // CEFR Badge
            HStack {
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
                
                Spacer()
            }
            
            // Phrase
            Text(phrase.text)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Translation
            Text(phrase.translation)
                .font(.body)
                .foregroundColor(.secondary)
            
            Divider()
            
            // Example
            VStack(alignment: .leading, spacing: 4) {
                Text("Example:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(phrase.example)
                    .font(.body)
                    .italic()
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
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

// MARK: - Grammar Nugget Card

struct GrammarNuggetCard: View {
    let nugget: GrammarNugget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // CEFR Badge (if available)
            if let cefr = nugget.cefr {
                HStack {
                    Text(cefr)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(cefrColor(for: cefr))
                        )
                    
                    Spacer()
                }
            }
            
            // Rule
            Text(nugget.rule)
                .font(.headline)
                .foregroundColor(.primary)
            
            Divider()
            
            // Example
            VStack(alignment: .leading, spacing: 4) {
                Text("Example:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(nugget.example)
                    .font(.body)
                    .italic()
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
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

// MARK: - Culture Note Card

struct CultureNoteCard: View {
    let note: CultureNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // CEFR Badge (if available)
            if let cefr = note.cefr {
                HStack {
                    Text(cefr)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(cefrColor(for: cefr))
                        )
                    
                    Spacer()
                }
            }
            
            // Culture Note Text
            Text(note.text)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
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

