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
        @State private var showingVoicePicker = false

        var body: some View {
            ScrollViewWithCustomNavBar {
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

                    // Speechify Monthly Usage
                    speechifyMonthlyUsageSection
                }
                .padding(12)
            } navigationBar: {
                NavigationBarView(title: Loc.Tts.dashboard, mode: .large, showsDismissButton: true)
            }
            .groupedBackground()
            .sheet(isPresented: $showingVoicePicker) {
                VoicePickerView()
            }
        }

        // MARK: - Header Section

        private var dashboardHeader: some View {
            CustomSectionView(header: Loc.Tts.premiumTtsDashboard) {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.title2)
                            .foregroundStyle(.accent)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(Loc.Tts.customizeTtsExperience)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    // Current status
                    HStack {
                        Circle()
                            .fill(ttsPlayer.isPlaying ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)

                        Text(ttsPlayer.isPlaying ? Loc.Tts.playing : Loc.Tts.ready)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(Loc.Tts.provider): \(ttsPlayer.selectedTTSProvider.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } trailingContent: {
                TagView(
                    text: Loc.Tts.pro,
                    systemImage: "crown.fill",
                    color: .systemYellow
                )
            }
        }

        // MARK: - Provider Section

        private var providerSection: some View {
            CustomSectionView(header: Loc.Tts.ttsProvider) {
                VStack(spacing: 8) {
                    ForEach(TTSProvider.allCases, id: \.self) { provider in
                        ProviderCard(
                            provider: provider,
                            isSelected: ttsPlayer.selectedTTSProvider == provider,
                            onTapAction: {
                                ttsPlayer.selectedTTSProvider = provider
                            }
                        )
                    }
                }
            }
        }

        // MARK: - Voice Customization Section

        private var voiceCustomizationSection: some View {
            CustomSectionView(header: Loc.Tts.voiceCustomization) {
                VStack(spacing: 12) {
                    // Current voice display
                    HStack(spacing: 8) {
                        Image(systemName: "person.wave.2.fill")
                            .foregroundStyle(.accent)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(Loc.Tts.currentVoice)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            if let currentVoice = ttsPlayer.selectedSpeechifyVoiceModel {
                                Text([currentVoice.name, currentVoice.languageDisplayName].joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(Loc.Tts.defaultVoice)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(vertical: 12, horizontal: 16)
                    .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 16))

                    // Voice preview
                    AsyncActionButton(
                        Loc.Tts.previewCurrentVoice,
                        systemImage: "play.circle.fill"
                    ) {
                        try await previewCurrentVoice()
                    }
                }
            } trailingContent: {
                HeaderButton(
                    Loc.Tts.changeVoice,
                    icon: "person.crop.circle.badge.plus",
                    size: .small
                ) {
                    showingVoicePicker = true
                }
            }
        }

        private var modelSection: some View {
            CustomSectionView(header: Loc.Tts.voiceCustomization) {
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

        private func previewCurrentVoice() async throws {
            if let currentVoice = ttsPlayer.selectedSpeechifyVoiceModel {
                try await ttsPlayer.previewSpeechifyVoice(currentVoice)
            } else {
                try await ttsPlayer.play(ttsPlayer.testText)
            }
        }

        // MARK: - Audio Settings Section

        private var audioSettingsSection: some View {
            CustomSectionView(header: Loc.Tts.audioSettings) {
                VStack(spacing: 16) {
                    // Speech Rate
                    AudioSettingSlider(
                        title: Loc.Tts.speechRate,
                        value: $ttsPlayer.speechRate,
                        range: 0.5...2.0,
                        icon: "speedometer"
                    )

                    // Volume
                    AudioSettingSlider(
                        title: Loc.Tts.volume,
                        value: $ttsPlayer.volume,
                        range: 0.0...1.0,
                        icon: "speaker.wave.2"
                    )
                }
            } trailingContent: {
                HeaderButton(
                    Loc.Actions.reset,
                    icon: "arrow.clockwise",
                    color: .red,
                    size: .small
                ) {
                    resetSettings()
                }
            }
        }

        // MARK: - Test Section

        private var testSection: some View {
            CustomSectionView(header: Loc.Tts.testYourSettings) {
                VStack(spacing: 12) {
                    TextField(Loc.Tts.enterTextToTest, text: $ttsPlayer.testText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(vertical: 12, horizontal: 16)
                        .clippedWithBackground(.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 12))
                        .lineLimit(3...6)

                    AsyncActionButton(
                        ttsPlayer.isPlaying ? Loc.Tts.stop : Loc.Tts.test,
                        systemImage: ttsPlayer.isPlaying ? "stop.fill" : "play.fill",
                        style: ttsPlayer.isPlaying ? .bordered : .borderedProminent
                    ) {
                        try await testTTS()
                    }
                    .disabled(ttsPlayer.isPlaying)
                }
            }
        }

        // MARK: - Usage Statistics Section

        private var usageStatisticsSection: some View {
            CustomSectionView(header: Loc.Tts.usageStatistics) {
                TTSAnalyticsView()
            }
        }

        // MARK: - Speechify Monthly Usage Section

        private var speechifyMonthlyUsageSection: some View {
            CustomSectionView(header: Loc.Tts.speechifyMonthlyUsage) {
                VStack(spacing: 12) {
                    // Usage Overview
                    FormWithDivider {
                        HStack {
                            Text(Loc.Tts.monthlyLimit)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(usageTracker.getMonthlySpeechifyLimit().formatted()) \(Loc.Tts.characters)")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.accent)
                        }
                        .padding(vertical: 12, horizontal: 16)

                        HStack {
                            Text(Loc.Tts.usedThisMonth)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(usageTracker.getCurrentMonthSpeechifyUsage().formatted()) \(Loc.Tts.characters)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(vertical: 12, horizontal: 16)

                        HStack {
                            Text(Loc.Tts.remaining)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(usageTracker.getRemainingSpeechifyCharacters().formatted()) \(Loc.Tts.characters)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(usageTracker.getRemainingSpeechifyCharacters() < 5000 ? .orange : .blue)
                        }
                        .padding(vertical: 12, horizontal: 16)
                    }
                    .clippedWithBackground(
                        Color.tertiarySystemGroupedBackground,
                        cornerRadius: 12
                    )

                    // Progress Bar
                    VStack(spacing: 8) {
                        HStack {
                            Text(Loc.Tts.usageProgress)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(String(format: "%.1f", usageTracker.getSpeechifyUsagePercentage()))%")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(usageTracker.getSpeechifyUsagePercentage() > 80 ? .orange : .blue)
                        }
                        
                        ProgressView(value: usageTracker.getSpeechifyUsagePercentage(), total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: usageTracker.getSpeechifyUsagePercentage() > 80 ? .orange : .blue))
                    }
                    .padding(vertical: 12, horizontal: 16)
                    .clippedWithBackground(.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 12))
                }
            }
        }

        // MARK: - Helper Methods

        private func testTTS() async throws {
            let language = ttsPlayer.availableVoices.first(where: { 
                $0.id == ttsPlayer.selectedSpeechifyVoice
            })?.language ?? "en-US"
            try await ttsPlayer.play(ttsPlayer.testText)
        }

        private func resetSettings() {
            ttsPlayer.speechRate = 1.0
            ttsPlayer.volume = 1.0
        }
    }

    // MARK: - Supporting Views

    struct ProviderCard: View {
        let provider: TTSProvider
        let isSelected: Bool
        let onTapAction: VoidHandler

        var body: some View {
            HStack {
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.accent)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(providerDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(vertical: 12, horizontal: 16)
            .clippedWithBackground(
                isSelected
                ? Color.accent.opacity(0.1)
                : Color.tertiarySystemGroupedBackground,
                cornerRadius: 16
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accent : Color.clear, lineWidth: 2)
            )
            .onTap {
                onTapAction()
            }
        }

        private var providerDescription: String {
            switch provider {
            case .google:
                return Loc.Tts.freeGoogleTtsDescription
            case .speechify:
                return Loc.Tts.Settings.speechifyDescription
            case .system:
                return "System"
            }
        }
    }

    // Removed unused VoiceCard struct

    struct AudioSettingSlider: View {
        let title: String
        @Binding var value: Double
        let range: ClosedRange<Double>
        let icon: String

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(.accent)
                        .frame(width: 20)

                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text(String(format: "%.1f", value))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Slider(value: $value, in: range, step: 0.1)
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
                        .foregroundStyle(color)
                        .font(.title2)

                    Spacer()
                }

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(vertical: 12, horizontal: 16)
            .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 16))
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
                        .foregroundStyle(.accent)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }

                // Voice info
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.headline)
                        .fontWeight(.medium)

                    Text(model.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(vertical: 12, horizontal: 16)
            .clippedWithBackground(
                isSelected
                ? Color.accent.opacity(0.1)
                : Color.tertiarySystemGroupedBackground,
                cornerRadius: 16
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accent : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
            .onTap {
                onSelect()
            }
        }
    }
}
