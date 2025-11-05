//
//  PracticeView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI
import AVFoundation

struct PracticeView: View {
    let song: Song
    let lyrics: SongLyrics
    @ObservedObject var viewModel: MusicDiscoveringViewModel
    
    @State private var selectedMode: PracticeMode = .shadowing
    @State private var isRecording = false
    @State private var recordingProgress: TimeInterval = 0
    @State private var fillInBlanks: [FillInBlankItem] = []
    @State private var fillInAnswers: [Int: String] = [:]
    @State private var karaokeLines: [String] = []
    @State private var currentKaraokeLine: Int = 0
    @State private var currentRecordingLine: Int?
    @State private var recordingURL: URL?
    @StateObject private var audioRecorder = AudioRecorder.shared
    
    enum PracticeMode: String, CaseIterable {
        case shadowing = "Shadowing"
        case fillIn = "Fill-in"
        case karaoke = "Karaoke Freestyle"
        
        var icon: String {
            switch self {
            case .shadowing:
                return "mic.fill"
            case .fillIn:
                return "text.insert"
            case .karaoke:
                return "music.mic"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Mode Selector
                Picker("Practice Mode", selection: $selectedMode) {
                    ForEach(PracticeMode.allCases, id: \.self) { mode in
                        HStack {
                            Image(systemName: mode.icon)
                            Text(mode.rawValue)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Mode-specific content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedMode {
                        case .shadowing:
                            shadowingView
                        case .fillIn:
                            fillInView
                        case .karaoke:
                            karaokeView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Shadowing View
    
    private var shadowingView: some View {
        VStack(spacing: 20) {
            Text("Shadowing Practice")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Record yourself saying each line, then compare with the original")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let lyricsText = lyrics.bestLyrics ?? lyrics.plainLyrics {
                let lines = lyricsText.components(separatedBy: .newlines).filter { !$0.isEmpty }
                
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    ShadowingLineView(
                        line: line,
                        isRecording: isRecording && currentRecordingLine == index,
                        onRecord: {
                            recordShadowing(line: line, index: index)
                        },
                        audioRecorder: audioRecorder
                    )
                }
            }
        }
    }
    
    // MARK: - Fill-in View
    
    private var fillInView: some View {
        VStack(spacing: 20) {
            Text("Fill in the Blanks")
                .font(.title2)
                .fontWeight(.bold)
            
            if fillInBlanks.isEmpty {
                Button("Generate Fill-in Exercise") {
                    generateFillInBlanks()
                }
                .padding()
            } else {
                ForEach(Array(fillInBlanks.enumerated()), id: \.offset) { index, blank in
                    FillInBlankView(
                        item: blank,
                        answer: fillInAnswers[blank.line] ?? "",
                        onAnswerChanged: { answer in
                            fillInAnswers[blank.line] = answer
                        }
                    )
                }
                
                Button("Check Answers") {
                    checkFillInAnswers()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
    }
    
    // MARK: - Karaoke View
    
    private var karaokeView: some View {
        VStack(spacing: 20) {
            Text("Karaoke Freestyle")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Every 4th line is removed - sing from memory!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if karaokeLines.isEmpty {
                Button("Start Karaoke Mode") {
                    generateKaraokeLines()
                }
                .padding()
            } else {
                ForEach(Array(karaokeLines.enumerated()), id: \.offset) { index, line in
                    if line.isEmpty {
                        // Blank line - user should sing
                        TextField("Sing this line...", text: .constant(""))
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                    } else {
                        Text(line)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func recordShadowing(line: String, index: Int) {
        Task {
            if audioRecorder.isRecording {
                // Stop current recording
                audioRecorder.stopRecording()
                await MainActor.run {
                    isRecording = false
                    currentRecordingLine = nil
                }
            } else {
                // Start recording
                do {
                    let url = try await audioRecorder.startRecording(line: line)
                    await MainActor.run {
                        isRecording = true
                        currentRecordingLine = index
                        recordingURL = url
                    }
                } catch {
                    await MainActor.run {
                        isRecording = false
                        currentRecordingLine = nil
                        // Show error to user
                        print("Failed to start recording: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func generateFillInBlanks() {
        // TODO: Get fill-in blanks from cached lesson template
        // For now, create simple blanks
        guard let lyricsText = lyrics.bestLyrics ?? lyrics.plainLyrics else { return }
        let lines = lyricsText.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        // Generate 3-5 blanks
        var blanks: [FillInBlankItem] = []
        for i in stride(from: 0, to: min(lines.count, 5), by: 1) {
            let line = lines[i]
            let words = line.components(separatedBy: .whitespaces)
            if let randomWord = words.randomElement() {
                blanks.append(FillInBlankItem(
                    line: i,
                    blankWord: randomWord,
                    options: [randomWord, "option2", "option3", "option4"]
                ))
            }
        }
        fillInBlanks = blanks
    }
    
    private func checkFillInAnswers() {
        // TODO: Check answers against correct answers from lesson template
        // For now, just show feedback
        print("Checking answers...")
    }
    
    private func generateKaraokeLines() {
        guard let lyricsText = lyrics.bestLyrics ?? lyrics.plainLyrics else { return }
        let lines = lyricsText.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        // Remove every 4th line
        var karaokeLines: [String] = []
        for (index, line) in lines.enumerated() {
            if (index + 1) % 4 == 0 {
                karaokeLines.append("") // Blank line
            } else {
                karaokeLines.append(line)
            }
        }
        self.karaokeLines = karaokeLines
    }
}

// MARK: - Shadowing Line View

struct ShadowingLineView: View {
    let line: String
    let isRecording: Bool
    let onRecord: () -> Void
    @ObservedObject var audioRecorder: AudioRecorder
    
    var body: some View {
        HStack {
            Text(line)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            if isRecording {
                // Show recording duration
                Text(formatDuration(audioRecorder.recordingDuration))
                    .font(.caption)
                    .foregroundColor(.red)
                    .monospacedDigit()
            }
            
            Button(action: onRecord) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title2)
                    .foregroundColor(isRecording ? .red : .accent)
            }
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Fill-in Blank View

struct FillInBlankView: View {
    let item: FillInBlankItem
    var answer: String
    let onAnswerChanged: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Line \(item.line + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // TODO: Show line with blank
            Text("Fill in the blank: ...")
                .font(.body)
            
            // Multiple choice options
            ForEach(Array(item.options.enumerated()), id: \.offset) { index, option in
                Button(action: {
                    onAnswerChanged(option)
                }) {
                    HStack {
                        Text(option)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if answer == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(answer == option ? Color.green.opacity(0.1) : Color.secondarySystemGroupedBackground)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
}

