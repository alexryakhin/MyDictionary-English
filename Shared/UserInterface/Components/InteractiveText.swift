//
//  InteractiveText.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/27/25.
//

import SwiftUI
import Flow

struct InteractiveText: View {

    struct SelectedWord: Identifiable {
        let id: String = UUID().uuidString
        let text: String
    }

    let text: String
    
    @State private var selectedWord: SelectedWord?

    var body: some View {
        HFlow(alignment: .top, spacing: .zero) {
            // Split text into words and create clickable elements
            let words = text.components(separatedBy: .whitespacesAndNewlines)
            
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                Menu {
                    let cleanWord = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
                    if cleanWord.isNotEmpty {
                        Section {
                            Button {
                                selectedWord = .init(text: cleanWord)
                            } label: {
                                Label(Loc.Words.addWord, systemImage: "plus")
                            }
                        } header: {
                            Text(cleanWord)
                        }
                    }
                } label: {
                    Text(word)
                        .font(.body)
                        .padding(vertical: 1, horizontal: 2)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(item: $selectedWord) { word in
            AddWordView(input: word.text, isWord: true)
        }
    }
}

// MARK: - Word Action Sheet (Removed - using Menu instead)

#Preview {
    VStack(spacing: 20) {
        InteractiveText(
            text: "It was a beautiful day in the park. The sky was blue, and the flowers were vibrant. Suddenly, a little girl picked up an apple from the ground. She exclaimed, \"Look at this shiny ___ apple!\" Everyone turned to see it, curious about its color."
        )
        .padding()
    }
}
