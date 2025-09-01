//
//  VoicePickerView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct VoicePickerView: View {
    @StateObject private var ttsPlayer = TTSPlayer.shared
    @State private var searchText = ""
    @State private var selectedLanguage: String?
    @State private var selectedGender: String?
    @State private var selectedUseCase: String?
    @State private var selectedAge: String?
    @State private var selectedTimbre: String?
    @State private var selectedAccent: String?

    var body: some View {
        ScrollViewWithCustomNavBar {
            voiceList
                .padding(12)
        } navigationBar: {
            NavigationBarView(
                title: Loc.Tts.Filters.selectVoice,
                mode: .large,
                showsDismissButton: true,
                bottomContent: {
                    VStack(spacing: 8) {
                        InputView.searchView(
                            Loc.Actions.search,
                            searchText: $searchText
                        )
                        FilterView(
                            selectedLanguage: $selectedLanguage,
                            selectedGender: $selectedGender,
                            selectedUseCase: $selectedUseCase,
                            selectedAge: $selectedAge,
                            selectedTimbre: $selectedTimbre,
                            selectedAccent: $selectedAccent
                        )
                    }
                }
            )
        }
        .groupedBackground()
    }

    // MARK: - Voice List

    private var voiceList: some View {
        CustomSectionView(header: Loc.Tts.Filters.availableVoices) {
            Group {
                if filteredVoices.isEmpty {
                    ContentUnavailableView(
                        Loc.Tts.Filters.noVoicesFound,
                        systemImage: "speaker.slash",
                        description: Text(
                            searchText.isEmpty
                            ? Loc.Tts.Filters.noVoicesAvailable
                            : Loc.Tts.Filters.noVoicesAvailable
                        )
                    )
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredVoices, id: \.id) { voice in
                            VoiceRowView(
                                voice: voice,
                                isSelected: ttsPlayer.selectedSpeechifyVoice == voice.id,
                                onSelect: {
                                    ttsPlayer.selectedSpeechifyVoice = voice.id
                                },
                                onPreview: {
                                    previewVoice(voice)
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var activeFiltersCount: Int {
        var count = 0
        if selectedLanguage != FilterView.All.languages.rawValue { count += 1 }
        if selectedGender != FilterView.All.genders.rawValue { count += 1 }
        if selectedUseCase != FilterView.All.useCases.rawValue { count += 1 }
        if selectedAge != FilterView.All.ages.rawValue { count += 1 }
        if selectedTimbre != FilterView.All.timbres.rawValue { count += 1 }
        if selectedAccent != FilterView.All.accents.rawValue { count += 1 }
        return count
    }

    private var filteredVoices: [SpeechifyVoice] {
        var voices = ttsPlayer.availableVoices

        // Apply search filter
        if !searchText.isEmpty {
            voices = voices.filter { voice in
                voice.name.localizedCaseInsensitiveContains(searchText) ||
                voice.language.localizedCaseInsensitiveContains(searchText) ||
                voice.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // Apply language filter
        if let selectedLanguage {
            voices = voices.filter { $0.language == selectedLanguage }
        }

        // Apply gender filter
        if let selectedGender {
            voices = voices.filter { $0.gender == selectedGender }
        }

        // Apply use case filter
        if let selectedUseCase {
            voices = voices.filter { $0.hasTag(category: "use-case", value: selectedUseCase) }
        }

        // Apply age filter
        if let selectedAge {
            voices = voices.filter { $0.hasTag(category: "age", value: selectedAge) }
        }

        // Apply timbre filter
        if let selectedTimbre {
            voices = voices.filter { $0.hasTag(category: "timbre", value: selectedTimbre) }
        }

        // Apply accent filter
        if let selectedAccent {
            voices = voices.filter { $0.hasTag(category: "accent", value: selectedAccent) }
        }

        return voices.sorted { $0.name < $1.name }
    }

    private func previewVoice(_ voice: SpeechifyVoice) {
        Task {
            do {
                try await ttsPlayer.previewSpeechifyVoice(voice)
            } catch {
                errorReceived(error)
            }
        }
    }
    
    private func languageDisplayName(for language: String) -> String {
        if language == FilterView.All.languages.rawValue {
            return FilterView.All.languages.displayName
        }
        return Locale.current.localizedString(forIdentifier: language) ?? language
    }

    // MARK: - Supporting Views

    struct VoiceRowView: View {
        let voice: SpeechifyVoice
        let isSelected: Bool
        let onSelect: () -> Void
        let onPreview: () -> Void

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
                    HStack {
                        Text(voice.name)
                            .font(.headline)
                            .fontWeight(.medium)

                        Spacer()

                        // Gender indicator
                        if let gender = voice.gender {
                            Text(gender.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(genderColor(for: gender).opacity(0.2))
                                .foregroundColor(genderColor(for: gender))
                                .cornerRadius(4)
                        }
                    }

                    Text(voice.languageDisplayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Tags
                    if !voice.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(voice.tags, id: \.self) { tag in
                                    Text(tagDisplayName(for: tag))
                                        .font(.caption2)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.1))
                                        .foregroundColor(.secondary)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }

                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .onTap(onPreview)
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

        private func genderColor(for gender: String) -> Color {
            switch gender.lowercased() {
            case "female": .systemPink
            case "male": .systemBlue
            default: .secondary
            }
        }
        
        private func tagDisplayName(for tag: String) -> String {
            let components = tag.split(separator: ":", maxSplits: 1)
            if components.count == 2 {
                return String(components[1])
            }
            return tag
        }
    }
}

// MARK: - Filter View

private struct FilterView: View {

    enum All: String {
        case languages = "all_languages"
        case genders = "all_genders"
        case useCases = "all_use_cases"
        case ages = "all_ages"
        case timbres = "all_timbres"
        case accents = "all_accents"

        var displayName: String {
            switch self {
            case .languages: Loc.Tts.Filters.allLanguages
            case .genders: Loc.Tts.Filters.allGenders
            case .useCases: Loc.Tts.Filters.allUseCases
            case .ages: Loc.Tts.Filters.allAges
            case .timbres: Loc.Tts.Filters.allTimbres
            case .accents: Loc.Tts.Filters.allAccents
            }
        }
    }

    @StateObject private var ttsPlayer: TTSPlayer = .shared

    @Binding var selectedLanguage: String?
    @Binding var selectedGender: String?
    @Binding var selectedUseCase: String?
    @Binding var selectedAge: String?
    @Binding var selectedTimbre: String?
    @Binding var selectedAccent: String?

    // Voice categories for filtering
    private var availableLanguages: [String] {
        Set(ttsPlayer.availableVoices.map { $0.language }).sorted()
    }

    private var availableGenders: [String] {
        Set(ttsPlayer.availableVoices.compactMap { $0.gender }).sorted()
    }

    private var availableUseCases: [String] {
        let useCases = ttsPlayer.availableVoices.flatMap { voice in
            voice.tagValues(for: "use-case")
        }
        return Array(Set(useCases)).sorted()
    }

    private var availableAges: [String] {
        let ages = ttsPlayer.availableVoices.flatMap { voice in
            voice.tagValues(for: "age")
        }
        return Array(Set(ages)).sorted()
    }

    private var availableTimbres: [String] {
        let timbres = ttsPlayer.availableVoices.flatMap { voice in
            voice.tagValues(for: "timbre")
        }
        return Array(Set(timbres)).sorted()
    }

    private var availableAccents: [String] {
        let accents = ttsPlayer.availableVoices.flatMap { voice in
            voice.tagValues(for: "accent")
        }
        return Array(Set(accents)).sorted()
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                var languageTitle: String {
                    guard let selectedLanguage else {
                        return FilterView.All.languages.displayName
                    }
                    return languageDisplayName(for: selectedLanguage)
                }
                HeaderButtonMenu(languageTitle, size: .small) {
                    Picker("Select language", selection: $selectedLanguage) {
                        Text(FilterView.All.languages.displayName)
                            .tag(String?.none)
                        ForEach(availableLanguages, id: \.self) { language in
                            Text(languageDisplayName(for: language))
                                .tag(language)
                        }
                    }
                    .pickerStyle(.inline)
                }

                var genderColor: Color {
                    switch selectedGender?.lowercased() {
                    case "male": .systemBlue
                    case "female": .systemPink
                    default: .accent
                    }
                }
                HeaderButtonMenu(
                    selectedGender?.localizedTtsFilter ?? FilterView.All.genders.displayName,
                    color: genderColor,
                    size: .small
                ) {
                    Picker("Select Gender", selection: $selectedGender) {
                        Text(FilterView.All.genders.displayName)
                            .tag(String?.none)
                        ForEach(availableGenders, id: \.self) { gender in
                            Text(gender.localizedTtsFilter).tag(gender)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                HeaderButtonMenu(
                    selectedUseCase?.localizedTtsFilter ?? FilterView.All.useCases.displayName,
                    color: .systemIndigo,
                    size: .small
                ) {
                    Picker("Select Use Case", selection: $selectedUseCase) {
                        Text(FilterView.All.useCases.displayName)
                            .tag(String?.none)
                        ForEach(availableUseCases, id: \.self) { useCase in
                            Text(useCase.localizedTtsFilter).tag(useCase)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                HeaderButtonMenu(
                    selectedAge?.localizedTtsFilter ?? FilterView.All.ages.displayName,
                    color: .systemPurple,
                    size: .small
                ) {
                    Picker("Select Age", selection: $selectedAge) {
                        Text(FilterView.All.ages.displayName)
                            .tag(String?.none)
                        ForEach(availableAges, id: \.self) { age in
                            Text(age.localizedTtsFilter).tag(age)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                HeaderButtonMenu(
                    selectedTimbre?.localizedTtsFilter ?? FilterView.All.timbres.displayName,
                    color: .systemOrange,
                    size: .small
                ) {
                    Picker("Select Timbre", selection: $selectedTimbre) {
                        Text(FilterView.All.timbres.displayName)
                            .tag(String?.none)
                        ForEach(availableTimbres, id: \.self) { timbre in
                            Text(timbre.localizedTtsFilter).tag(timbre)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                HeaderButtonMenu(
                    selectedAccent?.localizedTtsFilter ?? FilterView.All.accents.displayName,
                    color: .brown,
                    size: .small
                ) {
                    Picker("Select Accent", selection: $selectedAccent) {
                        Text(FilterView.All.accents.displayName)
                            .tag(String?.none)
                        ForEach(availableAccents, id: \.self) { accent in
                            Text(accent.localizedTtsFilter)
                                .tag(accent)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
        }
        .scrollClipDisabled()
    }
    
    private func languageDisplayName(for language: String) -> String {
        return Locale.current.localizedString(forIdentifier: language) ?? language
    }
}

private extension String {
    var localizedTtsFilter: String {
        let format = BundleToken.bundle.localizedString(forKey: self, value: self, table: "TTS")
        return String(format: format, locale: Locale.current)
    }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
