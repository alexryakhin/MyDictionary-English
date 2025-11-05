//
//  AudioRecorder.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import AVFoundation
import Combine

/// Service for recording audio for shadowing practice
final class AudioRecorder: NSObject, ObservableObject {
    
    static let shared = AudioRecorder()
    
    // MARK: - Published Properties
    
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var recordingURL: URL?
    
    // MARK: - Private Properties
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var audioSession: AVAudioSession?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Public Methods
    
    /// Request microphone permission
    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }
    
    /// Start recording audio
    /// - Parameter line: The line being practiced (for filename)
    /// - Returns: URL of the recorded file
    func startRecording(line: String? = nil) async throws -> URL {
        // Check permission
        guard await requestPermission() else {
            throw AudioRecordingError.permissionDenied
        }
        
        // Setup audio session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)
        
        // Create recording URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = line.map { "recording_\($0.prefix(20)).m4a" } ?? "recording_\(Date().timeIntervalSince1970).m4a"
        let recordingURL = documentsPath.appendingPathComponent(filename)
        
        // Remove existing file if it exists
        if FileManager.default.fileExists(atPath: recordingURL.path) {
            try FileManager.default.removeItem(at: recordingURL)
        }
        
        // Configure recorder settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // Create recorder
        let recorder = try AVAudioRecorder(url: recordingURL, settings: settings)
        recorder.delegate = self
        
        guard recorder.record() else {
            throw AudioRecordingError.failedToStart
        }
        
        await MainActor.run {
            self.audioRecorder = recorder
            self.recordingURL = recordingURL
            self.isRecording = true
            self.recordingDuration = 0
        }
        
        // Start timer
        startTimer()
        
        return recordingURL
    }
    
    /// Stop recording
    func stopRecording() {
        audioRecorder?.stop()
        stopTimer()
        
        Task { @MainActor in
            isRecording = false
            audioRecorder = nil
            
            // Deactivate audio session
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
    
    /// Cancel recording and delete file
    func cancelRecording() {
        stopRecording()
        
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
    }
    
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingDuration += 0.1
            }
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            Task { @MainActor in
                isRecording = false
                recordingURL = nil
            }
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            isRecording = false
            recordingURL = nil
        }
    }
}

// MARK: - Audio Recording Errors

enum AudioRecordingError: LocalizedError {
    case permissionDenied
    case failedToStart
    case recordingFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied"
        case .failedToStart:
            return "Failed to start recording"
        case .recordingFailed:
            return "Recording failed"
        }
    }
}

