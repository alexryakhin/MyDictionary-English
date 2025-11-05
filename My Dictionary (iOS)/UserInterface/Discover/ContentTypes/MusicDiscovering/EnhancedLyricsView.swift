//
//  EnhancedLyricsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI
import AVFoundation

// Note: CoreError is used by TranslationService but may not be in scope
// If translation fails, we'll show the original text

struct EnhancedLyricsView: View {
    let lyrics: SongLyrics
    let currentTime: TimeInterval
    let viewModel: MusicDiscoveringViewModel
    
    @State private var selectedWord: String?
    @State private var selectedLine: String?
    @State private var showingWordPopover = false
    @State private var showingTranslation = false
    @State private var translation: String?
    @State private var isLoadingTranslation = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let syncedLyrics = lyrics.syncedLyrics {
                        enhancedSyncedLyricsView(lyrics: syncedLyrics, proxy: proxy)
                    } else if let plainLyrics = lyrics.plainLyrics {
                        enhancedPlainLyricsView(lyrics: plainLyrics)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $showingWordPopover) {
            if let word = selectedWord {
                WordPopoverView(word: word, viewModel: viewModel)
            }
        }
        .alert("Translation", isPresented: $showingTranslation) {
            Button("OK", role: .cancel) { }
        } message: {
            if let translation = translation {
                Text(translation)
            }
        }
    }
    
    // MARK: - Enhanced Synced Lyrics
    
    private func enhancedSyncedLyricsView(lyrics: String, proxy: ScrollViewProxy) -> some View {
        let lines = parseSyncedLyrics(lyrics)
        
        return ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
            let isCurrent = isLineCurrent(index, lines: lines)
            
            VStack(alignment: .leading, spacing: 4) {
                // Main lyric line
                Text(line.text)
                    .font(.body)
                    .foregroundColor(isCurrent ? .primary : .secondary)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .padding(.vertical, 4)
                    .onTapGesture {
                        // Tap to translate line
                        translateLine(line.text)
                    }
                    .onLongPressGesture {
                        // Long press to show word selection
                        selectedLine = line.text
                        showWordSelection(for: line.text)
                    }
                
                // Show translation if available
                if showingTranslation && selectedLine == line.text, let translation = translation {
                    Text(translation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.leading, 8)
                }
            }
            .id(index)
            .onChange(of: currentTime) {
                if isCurrent {
                    withAnimation {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
        }
    }
    
    // MARK: - Enhanced Plain Lyrics
    
    private func enhancedPlainLyricsView(lyrics: String) -> some View {
        let lines = lyrics.components(separatedBy: .newlines)
        
        return ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
            VStack(alignment: .leading, spacing: 4) {
                // Main lyric line with tap-to-translate
                Text(line)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.vertical, 4)
                    .textSelection(.enabled)
                    .onTapGesture {
                        translateLine(line)
                    }
                    .onLongPressGesture {
                        selectedLine = line
                        showWordSelection(for: line)
                    }
                
                // Show translation if available
                if showingTranslation && selectedLine == line, let translation = translation {
                    Text(translation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.leading, 8)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseSyncedLyrics(_ lyrics: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        let pattern = #"\[(\d{2}):(\d{2})\.(\d{2})\](.*)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = lyrics as NSString
        let matches = regex?.matches(in: lyrics, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for match in matches {
            if match.numberOfRanges >= 4 {
                let minutes = Int(nsString.substring(with: match.range(at: 1))) ?? 0
                let seconds = Int(nsString.substring(with: match.range(at: 2))) ?? 0
                let centiseconds = Int(nsString.substring(with: match.range(at: 3))) ?? 0
                let text = nsString.substring(with: match.range(at: 4))
                
                let timestamp = TimeInterval(minutes * 60 + seconds) + TimeInterval(centiseconds) / 100.0
                lines.append(LyricLine(text: text.trimmingCharacters(in: .whitespaces), timestamp: timestamp))
            }
        }
        
        return lines
    }
    
    private func isLineCurrent(_ index: Int, lines: [LyricLine]) -> Bool {
        guard index < lines.count else { return false }
        let line = lines[index]
        let nextLineTimestamp = index + 1 < lines.count ? lines[index + 1].timestamp : Double.infinity
        
        return currentTime >= line.timestamp && currentTime < nextLineTimestamp
    }
    
    private func translateLine(_ line: String) {
        guard !isLoadingTranslation else { return }
        
        isLoadingTranslation = true
        
        Task {
            do {
                // Get user's language from locale
                let userLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
                
                // Detect source language or use target language from song
                // For now, auto-detect source language
                let translationService = GoogleTranslateService.shared
                
                // Translate the line
                let translatedText = try await translationService.translateDefinition(
                    line,
                    from: "auto", // Auto-detect source language
                    to: userLanguageCode
                )
                
                await MainActor.run {
                    translation = translatedText
                    showingTranslation = true
                    isLoadingTranslation = false
                }
            } catch let error as CoreError {
                // Handle CoreError translation errors
                print("Translation error: \(error)")
                await MainActor.run {
                    translation = line // Fallback to original text
                    showingTranslation = true
                    isLoadingTranslation = false
                }
            } catch {
                // Fallback to showing original text if translation fails
                print("Translation error: \(error.localizedDescription)")
                await MainActor.run {
                    translation = line
                    showingTranslation = true
                    isLoadingTranslation = false
                }
            }
        }
    }
    
    private func showWordSelection(for line: String) {
        // Show word selection UI
        // For now, extract first word as example
        let words = line.components(separatedBy: .whitespaces)
        if let firstWord = words.first?.trimmingCharacters(in: .punctuationCharacters) {
            selectedWord = firstWord
            showingWordPopover = true
        }
    }
}

// MARK: - Word Popover View

struct WordPopoverView: View {
    let word: String
    let viewModel: MusicDiscoveringViewModel
    
    @State private var pronunciation: String?
    @State private var cefrLevel: String?
    @State private var example: String?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Word
                Text(word)
                    .font(.title)
                    .fontWeight(.bold)
                
                // Pronunciation button
                Button(action: {
                    pronounceWord(word)
                }) {
                    HStack {
                        Image(systemName: "speaker.wave.2")
                        Text("Pronounce")
                    }
                    .padding()
                    .background(Color.accent.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // CEFR Level
                if let cefr = cefrLevel {
                    HStack {
                        Text("CEFR Level:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(cefr)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(cefrColor(for: cefr))
                            )
                    }
                }
                
                // Example
                if let example = example {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Example:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(example)
                            .font(.body)
                            .italic()
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Word Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
        }
        .onAppear {
            loadWordDetails()
        }
    }
    
    private func loadWordDetails() {
        // TODO: Load word details from AI service or cache
        cefrLevel = "B1"
        example = "Example sentence with \(word)"
    }
    
    private func pronounceWord(_ word: String) {
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES") // TODO: Get from user's language
        synthesizer.speak(utterance)
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

