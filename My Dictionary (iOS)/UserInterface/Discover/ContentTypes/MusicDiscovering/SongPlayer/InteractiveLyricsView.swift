//
//  InteractiveLyricsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct InteractiveLyricsView: View {
    let lyrics: SongLyrics
    let currentTime: TimeInterval
    let isScrollDisabled: Bool
    let onLineSelected: (TimeInterval) -> Void
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let syncedLyrics = lyrics.syncedLyrics {
                        syncedLyricsView(lyrics: syncedLyrics, proxy: proxy)
                    } else if let plainLyrics = lyrics.plainLyrics {
                        plainLyricsView(lyrics: plainLyrics)
                    } else {
                        noLyricsView
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 280) // Extra padding for bottom controls
            }
            .scrollDisabled(isScrollDisabled)
        }
    }
    
    // MARK: - Synced Lyrics View
    
    private func syncedLyricsView(lyrics: String, proxy: ScrollViewProxy) -> some View {
        let lines = parseSyncedLyrics(lyrics)
        
        return ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
            let isCurrent = isLineCurrent(index, lines: lines)
            
            Text(line.text)
                .font(.system(.title, design: .default, weight: .bold))
                .foregroundColor(isCurrent ? .primary : .secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(index)
                .onTapGesture {
                    // Seek to the line's timestamp when tapped
                    onLineSelected(line.timestamp)
                }
                .onChange(of: currentTime) { _, _ in
                    if isCurrent {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(index, anchor: .center)
                        }
                    }
                }
        }
    }
    
    // MARK: - Plain Lyrics View
    
    private func plainLyricsView(lyrics: String) -> some View {
        let lines = lyrics.components(separatedBy: .newlines)
        
        return ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
            Text(line)
                .font(.system(.title, design: .default, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }
    
    // MARK: - No Lyrics View
    
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
                
                let trimmedText = text.trimmingCharacters(in: .whitespaces)
                if !trimmedText.isEmpty {
                    lines.append(LyricLine(text: trimmedText, timestamp: timestamp))
                }
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

// MARK: - LyricLine Model

struct LyricLine {
    let text: String
    let timestamp: TimeInterval
}

// MARK: - Preview

#Preview {
    VStack {
        InteractiveLyricsView(
            lyrics: SongLyrics(
                plainLyrics: nil,
                syncedLyrics: "[00:17.12]La vida es un carnaval\n[00:20.45]Y las penas se van cantando\n[00:23.78]La vida es un carnaval\n[00:27.11]Es más bello vivir cantando",
                instrumental: false
            ),
            currentTime: 18.0,
            isScrollDisabled: false,
            onLineSelected: { timestamp in
                print("Selected line at timestamp: \(timestamp)")
            }
        )
        .groupedBackground()
    }
}

