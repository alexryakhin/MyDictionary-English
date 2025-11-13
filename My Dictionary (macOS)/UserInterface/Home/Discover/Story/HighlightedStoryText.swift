//
//  HighlightedStoryText.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct HighlightedStoryText: View {
    let text: String
    let font: Font
    let currentChunk: String?
    let sourceLanguageCode: String?
    
    init(text: String, font: Font = .body, currentChunk: String? = nil, sourceLanguageCode: String? = nil) {
        self.text = text
        self.font = font
        self.currentChunk = currentChunk
        self.sourceLanguageCode = sourceLanguageCode
    }
    
    var body: some View {
        // Split text into sentences
        let sentences = splitIntoSentences(text)
        
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(sentences.enumerated()), id: \.offset) { index, sentence in
                let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedChunk = currentChunk?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                
                // Check if this sentence matches the current chunk
                // Use fuzzy matching to account for slight differences in formatting
                let isHighlighted = !trimmedChunk.isEmpty && 
                    (trimmedSentence.localizedCaseInsensitiveContains(trimmedChunk) ||
                     trimmedChunk.localizedCaseInsensitiveContains(trimmedSentence))
                
                InteractiveText(
                    text: sentence,
                    font: font,
                    highlighted: isHighlighted,
                    sourceLanguageCode: sourceLanguageCode
                )
            }
        }
    }
    
    private func splitIntoSentences(_ text: String) -> [String] {
        // Split by sentence terminators while keeping them
        let pattern = #"([^.!?]+[.!?])\s*"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            // Fallback: simple split
            return text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex.matches(in: text, options: [], range: range)
        
        var sentences: [String] = []
        var lastIndex = 0
        
        for match in matches {
            if let sentenceRange = Range(match.range, in: text) {
                let sentence = String(text[sentenceRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty {
                    sentences.append(sentence)
                }
                lastIndex = match.range.location + match.range.length
            }
        }
        
        // Add remaining text if any
        if lastIndex < text.utf16.count {
            let remainingStartIndex = String.Index(utf16Offset: lastIndex, in: text)
            let remaining = String(text[remainingStartIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !remaining.isEmpty {
                sentences.append(remaining)
            }
        }
        
        return sentences.isEmpty ? [text] : sentences
    }
}

