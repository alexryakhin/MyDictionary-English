//
//  AIDemoView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct AIDemoView: View {
    @StateObject private var viewModel = AIDemoViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 50))
                            .foregroundColor(.accent)
                        
                        Text("AI Features Demo")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Test the AI-powered vocabulary learning features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // Show current language
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.accent)
                            Text("Response language: \(viewModel.currentLanguage)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                        
                        // Language info
                        Text("💡 Tip: Enter words in any language - AI will respond in your app's language")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }
                    .padding(.top)
                    
                    // Input Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Enter a word to test AI features:")
                            .font(.headline)
                        
                        TextField("e.g., serendipity, Drakaris, Когда рак на горе свистнет", text: $viewModel.inputWord)
                            .textFieldStyle(.roundedBorder)
                        
                        HStack {
                            Button("Clear") {
                                viewModel.clearInput()
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            Button("Test AI") {
                                Task {
                                    await viewModel.testAIFeatures()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.inputWord.isEmpty || viewModel.isProcessing)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Results Section
                    if viewModel.isProcessing {
                        VStack(spacing: 12) {
                            LoaderView()
                                .frame(width: 32, height: 32)

                            Text("AI is processing...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Word Information
                    if let wordInfo = viewModel.wordInformation {
                        AIDemoCard(
                            title: "Pronunciation",
                            icon: "speaker.wave.2",
                            content: wordInfo.pronunciation
                        )
                        
                        ForEach(Array(wordInfo.definitions.enumerated()), id: \.offset) { index, definition in
                            AIDemoCard(
                                title: "Definition \(index + 1) - \(definition.partOfSpeech)",
                                icon: "text.quote",
                                content: """
                                \(definition.definition)
                                
                                Examples:
                                \(definition.examples.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n"))
                                """
                            )
                        }
                    }
                    
                    // Error Display
                    if let error = viewModel.error {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title2)
                                .foregroundColor(.red)
                            
                            Text("Error")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color(.systemRed).opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("AI Demo")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - AI Demo Card

struct AIDemoCard: View {
    let title: String
    let icon: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accent)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
            }
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - AI Demo View Model

@MainActor
final class AIDemoViewModel: ObservableObject {
    @Published var inputWord = ""
    @Published var isProcessing = false
    @Published var wordInformation: AIWordResponse?
    @Published var error: String?
    
    private let aiService = AIService.shared
    
    var currentLanguage: String {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let languageCode = preferredLanguage.prefix(2).lowercased()
        
        // Map common language codes to full language names
        let languageMap: [String: String] = [
            "en": "English",
            "es": "Spanish", 
            "fr": "French",
            "de": "German",
            "it": "Italian",
            "pt": "Portuguese",
            "ru": "Russian",
            "ja": "Japanese",
            "ko": "Korean",
            "zh": "Chinese",
            "ar": "Arabic",
            "hi": "Hindi",
            "th": "Thai",
            "vi": "Vietnamese",
            "tr": "Turkish",
            "pl": "Polish",
            "nl": "Dutch",
            "sv": "Swedish",
            "da": "Danish",
            "no": "Norwegian",
            "fi": "Finnish",
            "cs": "Czech",
            "sk": "Slovak",
            "hu": "Hungarian",
            "ro": "Romanian",
            "bg": "Bulgarian",
            "hr": "Croatian",
            "sl": "Slovenian",
            "et": "Estonian",
            "lv": "Latvian",
            "lt": "Lithuanian",
            "el": "Greek",
            "he": "Hebrew",
            "id": "Indonesian",
            "ms": "Malay",
            "ca": "Catalan",
            "uk": "Ukrainian"
        ]
        
        return languageMap[languageCode] ?? "English"
    }
    
    func clearInput() {
        inputWord = ""
        wordInformation = nil
        error = nil
    }
    
    func testAIFeatures() async {
        print("🔍 [AIDemoView] testAIFeatures called with word: '\(inputWord)'")
        guard !inputWord.isEmpty else { 
            print("❌ [AIDemoView] Input word is empty")
            return 
        }
        
        print("🚀 [AIDemoView] Starting word information generation...")
        isProcessing = true
        error = nil
        
        do {
            print("🔍 [AIDemoView] Generating comprehensive word information...")
            wordInformation = try await aiService.request(.wordInfo(
                word: inputWord,
                maxDefinitions: 10,
                inputLanguage: .english
            ))
            print("✅ [AIDemoView] Word information generation completed")
            print("🎉 [AIDemoView] Successfully generated \(wordInformation?.definitions.count ?? 0) definitions")
            
        } catch {
            print("❌ [AIDemoView] Word information generation failed: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
        
        print("🔍 [AIDemoView] Setting isProcessing to false")
        isProcessing = false
    }
}

#Preview {
    AIDemoView()
}
