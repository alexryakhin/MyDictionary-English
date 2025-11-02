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
    let font: Font
    let highlighted: Bool
    let sourceLanguageCode: String?

    @State private var selectedWord: SelectedWord?
    @State private var translationWord: String?
    @State private var translationResult: String?
    @State private var isTranslating: Bool = false
    @StateObject private var ttsPlayer = TTSPlayer.shared
    
    private let translationService: TranslationService = GoogleTranslateService.shared
    private let languageDetector = LanguageDetector.shared
    
    private var currentLocaleLanguageCode: String {
        Locale.current.languageCode ?? "en"
    }
    
    private var shouldShowTranslateButton: Bool {
        // Determine source language code
        let sourceLangCode: String
        if let providedSourceLanguage = sourceLanguageCode {
            sourceLangCode = providedSourceLanguage
        } else {
            // If not provided, we'll need to detect it - but for the button visibility,
            // we can default to showing it if source is unknown
            return true
        }
        
        // Hide translate button if source language is the same as current locale
        return sourceLangCode.lowercased() != currentLocaleLanguageCode.lowercased()
    }

    init(text: String, font: Font = .body, highlighted: Bool = false, sourceLanguageCode: String? = nil) {
        self.text = text
        self.font = font
        self.highlighted = highlighted
        self.sourceLanguageCode = sourceLanguageCode
    }

    var body: some View {
        HFlow(alignment: .top, spacing: .zero) {
            // Split text into words and create clickable elements
            let words = text.components(separatedBy: .whitespacesAndNewlines)
            
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                Menu {
                    let cleanWord = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
                    if cleanWord.isNotEmpty {
                        Section {
                            // Add word button
                            Button {
                                selectedWord = .init(text: cleanWord)
                            } label: {
                                Label(Loc.Words.addWord, systemImage: "plus")
                            }
                            
                            // Listen button
                            Button {
                                Task {
                                    do {
                                        try await ttsPlayer.play(cleanWord)
                                    } catch {
                                        // Handle error silently
                                        print("TTS error: \(error.localizedDescription)")
                                    }
                                }
                            } label: {
                                Label(Loc.Actions.listen, systemImage: "speaker.wave.2.fill")
                            }
                            .disabled(ttsPlayer.isPlaying)
                        
                            // Copy button
                            Button {
                                copyToClipboard(cleanWord)
                                HapticManager.shared.triggerNotification(type: .success)
                            } label: {
                                Label(Loc.Actions.copy, systemImage: "doc.on.doc")
                            }

                            // Translate button (only show if source language differs from locale)
                            if shouldShowTranslateButton {
                                Button {
                                    Task {
                                        await translateWord(cleanWord)
                                    }
                                } label: {
                                    Label(Loc.Actions.translate, systemImage: "globe")
                                }
                                .disabled(isTranslating)
                            }
                        } header: {
                            Text(cleanWord)
                        }
                    }
                } label: {
                    Text(word)
                        .font(font)
                        .padding(vertical: 1, horizontal: 2)
                        .foregroundStyle(.primary)
                        .background(highlighted ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(item: $selectedWord) { word in
            AddWordView(input: word.text, isWord: true)
        }
        .alert(
            translationWord ?? "",
            isPresented: Binding(
                get: { translationResult != nil && translationWord != nil },
                set: { if !$0 { translationResult = nil; translationWord = nil } }
            )
        ) {
            Button(Loc.Actions.ok) {
                translationResult = nil
                translationWord = nil
            }
        } message: {
            Text(translationResult ?? "")
        }
    }
    
    // MARK: - Translation
    
    private func translateWord(_ word: String) async {
        guard !isTranslating else { return }
        
        let targetLanguageCode = currentLocaleLanguageCode
        
        // Use provided source language or detect it
        let detectedSourceLanguageCode: String
        if let providedSourceLanguage = sourceLanguageCode {
            detectedSourceLanguageCode = providedSourceLanguage
        } else {
            // Fallback to detection if not provided
            let detectedLanguage = languageDetector.detectLanguage(for: word)
            detectedSourceLanguageCode = detectedLanguage.languageCode
        }
        
        // If source language is the same as current locale, no translation needed
        if detectedSourceLanguageCode.lowercased() == targetLanguageCode.lowercased() {
            await MainActor.run {
                translationWord = word
                translationResult = word // No translation needed
                isTranslating = false
            }
            return
        }
        
        isTranslating = true
        
        do {
            let translatedText = try await translationService.translateDefinition(
                word,
                from: detectedSourceLanguageCode,
                to: targetLanguageCode
            )
            
            await MainActor.run {
                translationWord = word
                translationResult = translatedText
                isTranslating = false
                HapticManager.shared.triggerNotification(type: .success)
            }
        } catch {
            await MainActor.run {
                isTranslating = false
                HapticManager.shared.triggerNotification(type: .error)
                AlertCenter.shared.showAlert(
                    with: .error(
                        title: Loc.Errors.translationFailed,
                        message: error.localizedDescription
                    )
                )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        InteractiveText(
            text: "It was a beautiful day in the park. The sky was blue, and the flowers were vibrant. Suddenly, a little girl picked up an apple from the ground. She exclaimed, \"Look at this shiny ___ apple!\" Everyone turned to see it, curious about its color."
        )
        .padding()
    }
}
