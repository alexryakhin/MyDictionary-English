//
//  InteractiveLyricsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct InteractiveLyricsView: View {
    @ObservedObject var viewModel: SongPlayerViewModel
    
    @State private var isTranslating: Bool = false
    @State private var translationSource: String?
    @State private var translationResult: String?
    @State private var selectedWord: SelectedWord?
    @StateObject private var ttsPlayer = TTSPlayer.shared
    
    private let translationService: TranslationService = GoogleTranslateService.shared
    private let languageDetector = LanguageDetector.shared
    
    private var localeLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }
    
    private var lyrics: SongLyrics { viewModel.lyrics }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if let syncedLyrics = lyrics.syncedLyrics {
                        syncedLyricsView(lyrics: syncedLyrics, proxy: proxy)
                    } else if let plainLyrics = lyrics.plainLyrics {
                        plainLyricsView(lyrics: plainLyrics)
                    } else {
                        noLyricsView
                    }
                }
                .padding(vertical: 12, horizontal: 16)
            }
            .scrollDisabled(viewModel.isPlaying && lyrics.syncedLyrics != nil)
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
        .sheet(item: $selectedWord) { word in
            AddWordView(input: word.text, isWord: true)
        }
    }
    
    // MARK: - Synced Lyrics
    
    @ViewBuilder
    private func syncedLyricsView(lyrics: String, proxy: ScrollViewProxy) -> some View {
        let lines = parseSyncedLyrics(lyrics)
        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
            let isCurrent = isLineCurrent(index, lines: lines)
            Menu {
                Section(line.text) {
                    Button {
                        play(from: line.timestamp)
                    } label: {
                        Label(Loc.Actions.playFromHere, systemImage: "play.fill")
                    }
                    addToDictionaryButton(for: line.text)
                    listenButton(for: line.text)
                    copyButton(for: line.text)
                    if shouldShowTranslate(for: line.text) {
                        translateButton(for: line.text)
                    }
                }
            } label: {
                Text(line.text)
                    .font(.system(.title, design: .default, weight: .bold))
                    .foregroundColor(isCurrent ? .primary : .secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .id(index)
            .buttonStyle(.plain)
            .onChange(of: viewModel.currentTime) { _, _ in
                if isCurrent {
                    withAnimation {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
        }
    }
    
    // MARK: - Plain Lyrics
    
    @ViewBuilder
    private func plainLyricsView(lyrics: String) -> some View {
        let lines = lyrics.components(separatedBy: .newlines)
        ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            Menu {
                Section(line) {
                    addToDictionaryButton(for: trimmed)
                    listenButton(for: trimmed)
                    copyButton(for: trimmed)
                    if shouldShowTranslate(for: trimmed) {
                        translateButton(for: trimmed)
                    }
                }
            } label: {
                Text(line)
                    .font(.system(.title, design: .default, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Playback helpers
    
    private func play(from timestamp: TimeInterval) {
        viewModel.handle(.seek(to: timestamp))
        if !viewModel.isPlaying {
            viewModel.handle(.playPause)
        }
    }
    
    // MARK: - Action Buttons
    
    private func translateButton(for text: String) -> some View {
        Button {
            Task {
                await translateLine(text)
            }
        } label: {
            Label(Loc.Actions.translate, systemImage: "globe")
        }
        .disabled(isTranslating)
    }
    
    private func addToDictionaryButton(for text: String) -> some View {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return Button {
            guard cleaned.isNotEmpty else { return }
            selectedWord = SelectedWord(text: cleaned)
        } label: {
            Label(Loc.WordCollections.addToMyDictionary, systemImage: "plus")
        }
    }
    
    private func listenButton(for text: String) -> some View {
        Button {
            Task {
                do {
                    try await ttsPlayer.play(text)
                } catch {
                    print("TTS error: \(error.localizedDescription)")
                }
            }
        } label: {
            Label(Loc.Actions.listen, systemImage: "speaker.wave.2.fill")
        }
        .disabled(ttsPlayer.isPlaying)
    }
    
    private func copyButton(for text: String) -> some View {
        Button {
            copyToClipboard(text)
            HapticManager.shared.triggerNotification(type: .success)
        } label: {
            Label(Loc.Actions.copy, systemImage: "doc.on.doc")
        }
    }
    
    // MARK: - Helpers
    
    private func translateLine(_ text: String) async {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    private func detectedLanguageCode(for text: String) -> String {
        if let detected = lyrics.detectedLanguage?.rawValue {
            return detected
        }
        return languageDetector.detectLanguage(for: text).languageCode
    }
    
    private func shouldShowTranslate(for text: String) -> Bool {
        guard text.isNotEmpty else { return false }
        return detectedLanguageCode(for: text).lowercased() != localeLanguageCode.lowercased()
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
    
    private func parseSyncedLyrics(_ lyrics: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        let pattern = #"\[(\d{2}):(\d{2})\.(\d{2})\](.*)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = lyrics as NSString
        let matches = regex?.matches(in: lyrics, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        for match in matches where match.numberOfRanges >= 4 {
            let minutes = Int(nsString.substring(with: match.range(at: 1))) ?? 0
            let seconds = Int(nsString.substring(with: match.range(at: 2))) ?? 0
            let centiseconds = Int(nsString.substring(with: match.range(at: 3))) ?? 0
            let text = nsString.substring(with: match.range(at: 4)).trimmingCharacters(in: .whitespaces)
            guard text.isNotEmpty else { continue }
            let timestamp = TimeInterval(minutes * 60 + seconds) + TimeInterval(centiseconds) / 100.0
            lines.append(LyricLine(text: text, timestamp: timestamp))
        }
        return lines
    }
    
    private func isLineCurrent(_ index: Int, lines: [LyricLine]) -> Bool {
        guard index < lines.count else { return false }
        let line = lines[index]
        let nextTimestamp = index + 1 < lines.count ? lines[index + 1].timestamp : .infinity
        return viewModel.currentTime >= line.timestamp && viewModel.currentTime < nextTimestamp
    }
    
    private var noLyricsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No lyrics available")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

private struct SelectedWord: Identifiable {
    let id = UUID()
    let text: String
}

struct LyricLine {
    let text: String
    let timestamp: TimeInterval
}

