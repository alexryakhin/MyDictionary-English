//
//  TTSDashboardView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

enum TTSDashboard {
    struct ContentView: View {
        @StateObject private var ttsPlayer = TTSPlayer.shared
        @StateObject private var usageTracker = TTSUsageTracker.shared
        @State private var showingVoicePreview = false
        @State private var showingPremiumAlert = false
        @State private var showingVoicePicker = false

        var body: some View {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header
                    dashboardHeader

                    // Provider Selection
                    providerSection

                    if ttsPlayer.selectedTTSProvider == .speechify {
                        // Voice Customization
                        voiceCustomizationSection
                        // Voice Customization
                        modelSection

                        // Audio Settings
                        audioSettingsSection
                    }

                    // Test Section
                    testSection

                    // Usage Statistics
                    usageStatisticsSection
                }
                .padding(.horizontal, 16)
                .if(isPad) { view in
                    view
                        .frame(maxWidth: 550, alignment: .center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .groupedBackground()
            .navigation(title: "TTS Dashboard", mode: .large)
            .alert("Premium Feature", isPresented: $showingPremiumAlert) {
                Button("Upgrade to Pro") {
                    // Navigate to subscription screen
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("The TTS Dashboard is a premium feature. Upgrade to Pro to access advanced voice customization.")
            }
            .sheet(isPresented: $showingVoicePicker) {
                VoicePickerView()
            }
            .onAppear {
                checkPremiumAccess()
            }
        }

        // MARK: - Header Section

        private var dashboardHeader: some View {
            CustomSectionView(header: "Premium TTS Dashboard") {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.title2)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Customize your text-to-speech experience")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Premium badge
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("PRO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(6)
                    }

                    // Current status
                    HStack {
                        Circle()
                            .fill(ttsPlayer.isPlaying ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)

                        Text(ttsPlayer.isPlaying ? "Playing" : "Ready")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("Provider: \(ttsPlayer.selectedTTSProvider.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }

        // MARK: - Provider Section

        private var providerSection: some View {
            CustomSectionView(header: "TTS Provider") {
                VStack(spacing: 8) {
                    ForEach(TTSProvider.allCases, id: \.self) { provider in
                        ProviderCard(
                            provider: provider,
                            isSelected: ttsPlayer.selectedTTSProvider == provider,
                            onTap: {
                                if provider.isPremium && !SubscriptionService.shared.isProUser {
                                    showingPremiumAlert = true
                                } else {
                                    ttsPlayer.selectedTTSProvider = provider
                                }
                            }
                        )
                    }
                }
            }
        }

        // MARK: - Voice Customization Section

        private var voiceCustomizationSection: some View {
            CustomSectionView(header: "Voice Customization") {
                VStack(spacing: 12) {
                    // Current voice display
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Voice")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            if let currentVoice = ttsPlayer.availableVoices.first(where: { $0.id == ttsPlayer.selectedSpeechifyVoice }) {
                                Text(currentVoice.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(currentVoice.languageDisplayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Default Voice")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // Voice picker button
                        ActionButton(
                            "Change Voice",
                            systemImage: "person.crop.circle.badge.plus",
                            style: .bordered
                        ) {
                            showingVoicePicker = true
                        }
                    }
                    .padding(vertical: 12, horizontal: 16)
                    .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)

                    // Voice preview
                    ActionButton(
                        "Preview Current Voice",
                        systemImage: "play.circle.fill",
                        style: .borderedProminent
                    ) {
                        previewCurrentVoice()
                    }
                }
            }
        }

        private var modelSection: some View {
            CustomSectionView(header: "Voice Customization") {
                VStack(spacing: 12) {
                    ForEach(SpeechifyModel.allCases, id: \.self) { model in
                        ModelRowView(
                            model: model,
                            isSelected: ttsPlayer.selectedSpeechifyModel == model) {
                                ttsPlayer.selectedSpeechifyModel = model
                            }
                    }
                }
            }
        }

        private func previewCurrentVoice() {
            if let currentVoice = ttsPlayer.availableVoices.first(where: { $0.id == ttsPlayer.selectedSpeechifyVoice }) {
                previewVoice(currentVoice)
            } else {
                // Preview with default voice
                Task {
                    do {
                        try await ttsPlayer.play("Hello, this is a preview of the current voice.", targetLanguage: "en-US")
                    } catch {
                        print("Voice preview failed: \(error)")
                    }
                }
            }
        }

        // MARK: - Audio Settings Section

        private var audioSettingsSection: some View {
            CustomSectionView(header: "Audio Settings") {
                VStack(spacing: 16) {
                    // Speech Rate
                    AudioSettingSlider(
                        title: "Speech Rate",
                        value: $ttsPlayer.speechRate,
                        range: 0.5...2.0,
                        icon: "speedometer",
                        onChanged: { }
                    )

                    // Pitch
                    AudioSettingSlider(
                        title: "Pitch",
                        value: $ttsPlayer.pitch,
                        range: 0.5...2.0,
                        icon: "waveform",
                        onChanged: { }
                    )

                    // Volume
                    AudioSettingSlider(
                        title: "Volume",
                        value: $ttsPlayer.volume,
                        range: 0.0...1.0,
                        icon: "speaker.wave.2",
                        onChanged: { }
                    )
                }
            }
        }

        // MARK: - Test Section

        private var testSection: some View {
            CustomSectionView(header: "Test Your Settings") {
                VStack(spacing: 12) {
                    TextField("Enter text to test...", text: $ttsPlayer.testText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)

                    HStack(spacing: 8) {
                        ActionButton(
                            ttsPlayer.isPlaying ? "Stop" : "Test",
                            systemImage: ttsPlayer.isPlaying ? "stop.fill" : "play.fill",
                            style: ttsPlayer.isPlaying ? .bordered : .borderedProminent
                        ) {
                            testTTS()
                        }
                        .disabled(ttsPlayer.isPlaying)

                        ActionButton("Reset", systemImage: "arrow.clockwise") {
                            resetSettings()
                        }
                    }
                }
            }
        }

        // MARK: - Usage Statistics Section

        private var usageStatisticsSection: some View {
            CustomSectionView(header: "Usage Statistics") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    StatCard(
                        title: "Characters Used",
                        value: usageTracker.totalCharactersFormatted,
                        icon: "textformat.abc",
                        color: .blue
                    )

                    StatCard(
                        title: "Sessions",
                        value: usageTracker.totalSessionsFormatted,
                        icon: "play.circle",
                        color: .green
                    )

                    StatCard(
                        title: "Favorite Voice",
                        value: usageTracker.favoriteVoice,
                        icon: "person.circle",
                        color: .purple
                    )

                    StatCard(
                        title: "Time Saved",
                        value: usageTracker.timeSaved,
                        icon: "clock",
                        color: .orange
                    )
                }
            }
        }

        // MARK: - Helper Methods

        private func checkPremiumAccess() {
            if !SubscriptionService.shared.isProUser {
                showingPremiumAlert = true
            }
        }

        private func testTTS() {
            Task {
                do {
                    // Get language from current voice or use default
                    let language = ttsPlayer.availableVoices.first(where: { $0.id == ttsPlayer.selectedSpeechifyVoice })?.language ?? "en-US"
                    try await ttsPlayer.play(ttsPlayer.testText, targetLanguage: language)
                } catch {
                    print("TTS test failed: \(error)")
                }
            }
        }

        private func previewVoice(_ voice: SpeechifyVoice) {
            ttsPlayer.selectedSpeechifyVoice = voice.id
            testTTS()
        }

        private func resetSettings() {
            ttsPlayer.speechRate = 1.0
            ttsPlayer.pitch = 1.0
            ttsPlayer.volume = 1.0
        }
    }

    // MARK: - Supporting Views

    struct ProviderCard: View {
        let provider: TTSProvider
        let isSelected: Bool
        let onTap: () -> Void

        var body: some View {
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(provider.displayName)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            if provider.isPremium {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }

                        Text(providerDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                }
                .padding(vertical: 12, horizontal: 16)
                .clippedWithBackground(isSelected ? Color.blue.opacity(0.1) : Color.tertiarySystemGroupedBackground, cornerRadius: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }

        private var providerDescription: String {
            switch provider {
            case .google:
                return "Free Google TTS with basic voices and reliable performance"
            case .speechify:
                return "Premium AI-powered voices with natural pronunciation and customization"
            }
        }
    }

    // Removed unused VoiceCard struct

    struct AudioSettingSlider: View {
        let title: String
        @Binding var value: Double
        let range: ClosedRange<Double>
        let icon: String
        let onChanged: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .frame(width: 20)

                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text(String(format: "%.1f", value))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Slider(value: $value, in: range, step: 0.1)
                    .onChange(of: value) { _ in
                        onChanged()
                    }
            }
        }
    }

    struct StatCard: View {
        let title: String
        let value: String
        let icon: String
        let color: Color

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)

                    Spacer()
                }

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(vertical: 12, horizontal: 16)
            .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
        }
    }

    struct ModelRowView: View {
        let model: SpeechifyModel
        let isSelected: Bool
        let onSelect: () -> Void

        var body: some View {
            HStack(spacing: 12) {
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }

                // Voice info
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.headline)
                        .fontWeight(.medium)

                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(vertical: 12, horizontal: 16)
            .clippedWithBackground(isSelected ? Color.blue.opacity(0.1) : Color.tertiarySystemGroupedBackground, cornerRadius: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
        }
    }
}
