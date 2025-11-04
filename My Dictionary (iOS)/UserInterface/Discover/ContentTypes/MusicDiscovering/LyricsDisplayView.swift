//
//  LyricsDisplayView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct LyricsDisplayView: View {
    let lyrics: SongLyrics
    let currentTime: TimeInterval
    
    @State private var highlightedLineIndex: Int?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let syncedLyrics = lyrics.syncedLyrics {
                        // Display synced lyrics with highlighting
                        syncedLyricsView(lyrics: syncedLyrics, proxy: proxy)
                    } else if let plainLyrics = lyrics.plainLyrics {
                        // Display plain lyrics
                        plainLyricsView(lyrics: plainLyrics)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Synced Lyrics View
    
    private func syncedLyricsView(lyrics: String, proxy: ScrollViewProxy) -> some View {
        let lines = parseSyncedLyrics(lyrics)
        
        return ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
            Text(line.text)
                .font(.body)
                .foregroundColor(isLineCurrent(index, lines: lines) ? .primary : .secondary)
                .fontWeight(isLineCurrent(index, lines: lines) ? .semibold : .regular)
                .padding(.vertical, 4)
                .id(index)
                .onChange(of: currentTime) {
                    if isLineCurrent(index, lines: lines) {
                        withAnimation {
                            proxy.scrollTo(index, anchor: .center)
                        }
                        highlightedLineIndex = index
                    }
                }
        }
    }
    
    // MARK: - Plain Lyrics View
    
    private func plainLyricsView(lyrics: String) -> some View {
        let lines = lyrics.components(separatedBy: .newlines)
        
        return ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
            Text(line)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.vertical, 4)
                .textSelection(.enabled)
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
}

struct LyricLine {
    let text: String
    let timestamp: TimeInterval
}

#Preview {
    LyricsDisplayView(
        lyrics: SongLyrics(
            plainLyrics: "La vida es un carnaval\nY las penas se van cantando",
            syncedLyrics: "[00:17.12]La vida es un carnaval\n[00:20.45]Y las penas se van cantando",
            instrumental: false
        ),
        currentTime: 18.0
    )
    .padding()
}

