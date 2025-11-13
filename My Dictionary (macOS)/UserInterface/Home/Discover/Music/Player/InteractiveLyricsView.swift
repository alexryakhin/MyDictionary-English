//
//  InteractiveLyricsView.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 11/12/25.
//

import SwiftUI
import AppKit

struct InteractiveLyricsView: View {
    @ObservedObject var viewModel: SongPlayerMacViewModel
    
    @State private var isTranslating: Bool = false
    @State private var translationSource: String?
    @State private var translationResult: String?
    @State private var showMenu: LyricLine?
    @State private var addToDictionary: LyricLine?
    @StateObject private var ttsPlayer = TTSPlayer.shared

    private let translationService: TranslationService = GoogleTranslateService.shared
    private let languageDetector = LanguageDetector.shared
    
    private var localeLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.parsedSyncedLines.isNotEmpty {
                        syncedLyricsView()
                    } else if let plainLyrics = viewModel.lyrics.plainLyrics {
                        plainLyricsView(lyrics: plainLyrics)
                    } else {
                        noLyricsView
                    }
                }
                .padding(vertical: 12, horizontal: 16)
            }
            .onChange(of: viewModel.currentLineIndex) { _, newIndex in
                if let newIndex {
                    withAnimation {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
        .alert(translationSource ?? "", isPresented: Binding(
            get: { translationResult != nil && translationSource != nil },
            set: { if !$0 { translationSource = nil; translationResult = nil } }
        )) {
            Button(Loc.Actions.ok) {
                translationSource = nil
                translationResult = nil
            }
        } message: {
            Text(translationResult ?? "")
        }
        .sheet(item: $addToDictionary) { line in
            let config = AddWordConfig(
                input: line.text,
                inputLanguage: viewModel.lyrics.detectedLanguage,
                selectedDictionaryId: nil,
                isWord: line.text.components(separatedBy: .init(charactersIn: " ")).count == 1
            )
            AddWordView(config: config)
        }
        .sheet(item: $showMenu) { line in
            ScrollViewWithCustomNavBar {
                VStack(alignment: .leading) {
                    Text(line.text)
                        .font(.headline)
                        .padding(.bottom, 12)

                    if viewModel.parsedSyncedLines.isNotEmpty {
                        Button {
                            play(from: line.timestamp)
                            showMenu = nil
                        } label: {
                            Label(Loc.Actions.playFromHere, systemImage: "play.fill")
                        }
                    }
                    addToDictionaryButton(for: line)
                    listenButton(for: line)
                    copyButton(for: line)
                    if shouldShowTranslate(for: line.text) {
                        translateButton(for: line)
                    }
                }
                .padding(vertical: 12, horizontal: 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            } navigationBar: {
                NavigationBarView(
                    title: Loc.MusicDiscovering.InteractiveLyrics.Menu.options,
                    mode: .regular,
                    showsDismissButton: true
                )
            }
            .frame(width: 300, height: 300)
        }
    }
    
    @ViewBuilder
    private func syncedLyricsView() -> some View {
        ForEach(Array(viewModel.parsedSyncedLines.enumerated()), id: \.offset) { index, line in
            Text(line.text)
                .font(.system(.title, design: .default, weight: .bold))
                .foregroundColor(viewModel.currentLineIndex == index ? .primary : .secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .id(index)
                .onTapGesture {
                    showMenu = line
                }
        }
    }
    
    @ViewBuilder
    private func plainLyricsView(lyrics: String) -> some View {
        let lines = lyrics.components(separatedBy: .newlines)
        ForEach(Array(lines.enumerated()), id: \.offset) { _, lineText in
            Text(lineText)
                .font(.system(.title, design: .default, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .onTapGesture {
                    let trimmed = lineText.trimmingCharacters(in: .whitespacesAndNewlines)
                    showMenu = .init(text: trimmed, timestamp: .zero)
                }
        }
    }
    
    private func play(from timestamp: TimeInterval) {
        viewModel.handle(.seek(to: timestamp))
        if !viewModel.isPlaying {
            viewModel.handle(.playPause)
        }
    }
    
    private func translateButton(for line: LyricLine) -> some View {
        Button {
            Task {
                await translateLine(line)
                showMenu = nil
            }
        } label: {
            Label(Loc.Actions.translate, systemImage: "globe")
        }
        .disabled(isTranslating)
    }
    
    private func addToDictionaryButton(for line: LyricLine) -> some View {
        let cleaned = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return Button {
            guard cleaned.isNotEmpty else { return }
            showMenu = nil
            addToDictionary = LyricLine(text: cleaned, timestamp: .zero)
        } label: {
            Label(Loc.WordCollections.addToMyDictionary, systemImage: "plus")
        }
    }
    
    private func listenButton(for line: LyricLine) -> some View {
        Button {
            Task {
                do {
                    try await ttsPlayer.play(line.text)
                    if viewModel.isPlaying {
                        viewModel.handle(.playPause)
                    }
                    showMenu = nil
                } catch {
                    print("TTS error: \(error.localizedDescription)")
                }
            }
        } label: {
            Label(Loc.Actions.listen, systemImage: "speaker.wave.2.fill")
        }
        .disabled(ttsPlayer.isPlaying)
    }
    
    private func copyButton(for line: LyricLine) -> some View {
        Button {
            copyToClipboard(line.text)
            showMenu = nil
        } label: {
            Label(Loc.Actions.copy, systemImage: "doc.on.doc")
        }
    }
    
    private func translateLine(_ line: LyricLine) async {
        let cleaned = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, !isTranslating else { return }
        let sourceLanguage = detectedLanguageCode(for: cleaned)
        let targetLanguage = localeLanguageCode
        if sourceLanguage.lowercased() == targetLanguage.lowercased() {
            translationSource = cleaned
            translationResult = cleaned
            return
        }
        isTranslating = true
        do {
            let translated = try await translationService.translateDefinition(
                cleaned,
                from: sourceLanguage,
                to: targetLanguage
            )
            await MainActor.run {
                translationSource = cleaned
                translationResult = translated
                isTranslating = false
            }
        } catch {
            await MainActor.run {
                isTranslating = false
                AlertCenter.shared.showAlert(
                    with: .error(
                        title: Loc.Errors.translationFailed,
                        message: error.localizedDescription
                    )
                )
            }
        }
    }
    
    private func detectedLanguageCode(for text: String) -> String {
        if let detected = viewModel.lyrics.detectedLanguage?.rawValue {
            return detected
        }
        return languageDetector.detectLanguage(for: text).languageCode
    }
    
    private func shouldShowTranslate(for text: String) -> Bool {
        guard text.isNotEmpty else { return false }
        return detectedLanguageCode(for: text).lowercased() != localeLanguageCode.lowercased()
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private var noLyricsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(Loc.MusicDiscovering.InteractiveLyrics.Empty.title)
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct LyricLine: Identifiable {
    let id = UUID()
    let text: String
    let timestamp: TimeInterval
}

