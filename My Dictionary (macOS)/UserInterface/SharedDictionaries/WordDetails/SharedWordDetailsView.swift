//
//  SharedWordDetailsView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/1/25.
//

import SwiftUI
import Combine
import Flow

struct SharedWordDetailsView: View {

    @Environment(\.dismiss) private var dismiss

    @FocusState private var isPhoneticsFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isNotesFocused: Bool

    @State private var showingDetailedStatistics: Bool = false
    @State private var showingMeaningsList: Bool = false
    @State private var meaningToEdit: SharedWordMeaning?
    @State private var image: Image?
    @State private var scrollOffset: CGFloat = .zero
    @State private var shouldHaveNavigationTitle: Bool = false
    @State private var showingImageSelection = false
    @State private var showingImageOnboarding = false
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var paywallService = PaywallService.shared

    // Mutable state for editable fields
    @State private var phoneticText: String = ""
    @State private var definitionText: String = ""
    @State private var notesText: String = ""

    @StateObject private var dictionaryService = DictionaryService.shared
    @StateObject private var authenticationService = AuthenticationService.shared
    @StateObject private var ttsPlayer = TTSPlayer.shared

    @State private var word: SharedWord
    private let dictionaryId: String

    private var canEdit: Bool {
        guard let dictionary = dictionaryService.sharedDictionaries.first(where: { $0.id == dictionaryId }) else {
            return false
        }
        return dictionary.canEdit
    }
    
    var imageExists: Bool {
        (word.imageLocalPath != nil || image != nil) && subscriptionService.isProUser
    }
    
    var hasImageAvailable: Bool {
        word.imageLocalPath != nil || image != nil
    }

    init(word: SharedWord, dictionaryId: String) {
        self._word = State(wrappedValue: word)
        self.dictionaryId = dictionaryId
        // Initialize mutable state with current word values
        self._phoneticText = State(wrappedValue: word.phonetic ?? "")
        self._definitionText = State(wrappedValue: word.definition)
        self._notesText = State(wrappedValue: word.notes ?? "")
    }

    var body: some View {
        ScrollViewWithReader(scrollOffset: $scrollOffset) {
            VStack(spacing: 0) {
                // Hero Image Section (only show if user is pro)
                if let image, subscriptionService.isProUser {
                    heroImageView(image: image)
                        .overlay(alignment: .bottom) {
                            wordHeaderView
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                        }
                }
                
                // Content Sections
                LazyVStack(spacing: 8) {
                    if !hasImageAvailable && canEdit {
                        // Image Section (only show if no image exists and user can edit)
                        imageSectionView
                    } else if hasImageAvailable && !subscriptionService.isProUser {
                        // Image Premium Section (show if image exists but user is not pro)
                        imagePremiumSectionView
                    }
                    
                    transcriptionSectionView
                    partOfSpeechSectionView
                    meaningsSectionView
                    notesSectionView
                    languageSectionView
                    collaborativeFeaturesSection
                    
                    // Remove Image Button (only show if image exists and user can edit)
                    if hasImageAvailable && canEdit && subscriptionService.isProUser {
                        removeImageButton
                    }
                }
                .padding(12)
                .animation(.default, value: word)
            }
        }
        .safeAreaInset(edge: .top) {
            Text(word.wordItself)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .padding(.top, 16)
                .background {
                    VStack(spacing: 0) {
                        Color.clear
                            .glassBackgroundEffectIfAvailable(.regular, in: .rect)
                            .if(isGlassAvailable == false) {
                                $0.background(.ultraThinMaterial)
                            }
                        Divider()
                    }
                    .opacity(shouldHaveNavigationTitle ? 1 : 0)
                }
                .opacity(shouldHaveNavigationTitle ? 1 : 0)
        }
        .groupedBackground()
        .navigationTitle(Loc.Navigation.wordDetails)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Like button
                Button {
                    toggleLike()
                } label: {
                    HStack {
                        Image(systemName: word.isLikedBy(authenticationService.userEmail ?? "") ? "heart.fill" : "heart")
                        Text(word.likeCount.formatted())
                    }
                }
                .help(Loc.Actions.toggleLike)

                if canEdit {
                    // Delete button
                    Button {
                        showDeleteAlert()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .help(Loc.Words.deleteWord)
                }
            }
        }

        .sheet(isPresented: $showingDetailedStatistics) {
            SharedWordDifficultyStatsView(word: word)
        }
        .sheet(isPresented: $showingMeaningsList) {
            SharedMeaningsListView(word: $word, dictionaryId: dictionaryId)
        }
        .sheet(item: $meaningToEdit) { meaning in
            SharedMeaningEditView(meaning: meaning, dictionaryId: dictionaryId, wordId: word.id)
        }
        .sheet(isPresented: $showingImageSelection) {
            ImageSelectionView(
                word: word.wordItself,
                language: .english,
                onImageSelected: { imageUrl, localPath in
                    // Update the word with the new image
                    var updatedWord = word
                    updatedWord.imageUrl = imageUrl
                    updatedWord.imageLocalPath = localPath

                    // Update the image state
                    if let image = PexelsService.shared.getImageFromLocalPath(localPath) {
                        self.image = image
                        shouldHaveNavigationTitle = false
                    }

                    Task {
                        await saveWordToFirebase(updatedWord)
                    }
                },
                onDismiss: {
                    showingImageSelection = false
                }
            )
        }
        .imagesOnboarding(isPresented: $showingImageOnboarding, onCompleted: handleOnboardingCompletion)
        .task {
            await loadImage()
            // Start real-time listener for this specific word
            dictionaryService.startSharedWordListener(
                dictionaryId: dictionaryId,
                wordId: word.id
            ) { updatedWord in
                guard let updatedWord else { return }

                // Update the word state on the main thread
                DispatchQueue.main.async {
                    self.word = updatedWord
                    // Also update the local state variables to keep them in sync
                    self.phoneticText = updatedWord.phonetic ?? ""
                    self.definitionText = updatedWord.definition
                    self.notesText = updatedWord.notes ?? ""
                }
            }
        }
        .onChange(of: scrollOffset) { newValue in
            guard hasImageAvailable && subscriptionService.isProUser else {
                shouldHaveNavigationTitle = true
                return
            }
            let topOffset: CGFloat = 200
            withAnimation {
                shouldHaveNavigationTitle = newValue <= -topOffset
            }
        }
        .onDisappear {
            // Stop the real-time listener when leaving the view
            dictionaryService.stopSharedWordListener(dictionaryId: dictionaryId, wordId: word.id)
        }
    }

    private var transcriptionSectionView: some View {
        CustomSectionView(header: Loc.Words.transcription, headerFontStyle: .stealth) {
            if canEdit {
                TextField(Loc.Words.transcription, text: $phoneticText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .focused($isPhoneticsFocused)
                    .fontWeight(.semibold)
            } else {
                Text(phoneticText.nilIfEmpty ?? Loc.Words.noTranscription)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.semibold)
            }
        } trailingContent: {
            if isPhoneticsFocused {
                HeaderButton(Loc.Actions.done, size: .small) {
                    isPhoneticsFocused = false
                    savePhonetic()
                }
            } else {
                AsyncHeaderButton(
                    Loc.Actions.listen,
                    icon: "speaker.wave.2.fill",
                    size: .small
                ) {
                    try await play(word.wordItself, isWord: true)
                }
                .disabled(ttsPlayer.isPlaying)
            }
        }
    }

    private var partOfSpeechSectionView: some View {
        CustomSectionView(header: Loc.Words.partOfSpeech, headerFontStyle: .stealth) {
            Text(PartOfSpeech(rawValue: word.partOfSpeech).displayName)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
        } trailingContent: {
            if canEdit {
                HeaderButtonMenu(Loc.Actions.edit, size: .small) {
                    ForEach(PartOfSpeech.allCases, id: \.self) { partCase in
                        Button {
                            updatePartOfSpeech(partCase)
                        } label: {
                            Text(partCase.displayName)
                        }
                    }
                }
            }
        }
    }

    private var meaningsSectionView: some View {
        let meanings = word.meanings
        let showLimited = meanings.count > 3
        let displayMeanings = showLimited ? Array(meanings.prefix(3)) : meanings

        return CustomSectionView(
            header: meanings.count > 1 ? "\(Loc.Words.meanings) (\(meanings.count))" : Loc.Words.meaning,
            headerFontStyle: .stealth,
            hPadding: .zero
        ) {
            if meanings.isEmpty {
                // Fallback to legacy definition if no meanings exist
                if canEdit {
                    TextField(Loc.Words.WordDetails.definition, text: $definitionText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .focused($isDefinitionFocused)
                        .fontWeight(.semibold)
                        .padding(vertical: 12, horizontal: 16)
                } else {
                    Text(definitionText.nilIfEmpty ?? Loc.Words.noDefinition)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fontWeight(.semibold)
                        .padding(vertical: 12, horizontal: 16)
                }
            } else {
                FormWithDivider {
                    ForEach(Array(displayMeanings.enumerated()), id: \.element.id) { index, meaning in
                        meaningRowView(meaning: meaning, index: index + 1)
                    }
                }

                if showLimited {
                    HeaderButton(
                        "\(Loc.Words.showAllMeanings) (\(meanings.count))",
                        icon: "list.number",
                        size: .small
                    ) {
                        showingMeaningsList = true
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } trailingContent: {
            if meanings.isEmpty {
                // Legacy definition controls
                if isDefinitionFocused {
                    HeaderButton(Loc.Actions.done, size: .small) {
                        isDefinitionFocused = false
                        saveDefinition()
                        AnalyticsService.shared.logEvent(.wordDefinitionChanged)
                    }
                } else {
                    AsyncHeaderButton(
                        Loc.Actions.listen,
                        icon: "speaker.wave.2.fill",
                        size: .small
                    ) {
                        try await play(word.definition)
                        AnalyticsService.shared.logEvent(.wordDefinitionPlayed)
                    }
                    .disabled(ttsPlayer.isPlaying)
                }
            } else {
                if canEdit {
                    HeaderButton(icon: "plus", size: .small) {
                        addNewMeaning()
                    }
                }
            }
        }
    }

    private var notesSectionView: some View {
        CustomSectionView(
            header: Loc.Words.notes,
            headerFontStyle: .stealth
        ) {
            if canEdit {
                TextField(Loc.Words.addNotes, text: $notesText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .focused($isNotesFocused)
                    .fontWeight(.semibold)
            } else {
                Text(notesText.nilIfEmpty ?? Loc.Words.noNotes)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.semibold)
            }
        } trailingContent: {
            if isNotesFocused {
                HeaderButton(Loc.Actions.done, size: .small) {
                    isNotesFocused = false
                    saveNotes()
                }
            }
        }
    }

    @ViewBuilder
    private var languageSectionView: some View {
        CustomSectionView(header: Loc.Words.language, headerFontStyle: .stealth) {
            HStack {
                Text(word.languageDisplayName)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TagView(
                    text: word.languageCode.uppercased(),
                    color: .blue,
                    size: .mini
                )
            }
        } trailingContent: {
            HeaderButtonMenu(Loc.Actions.edit, size: .small) {
                ForEach(InputLanguage.allCasesSorted, id: \.self) { lang in
                    Button {
                        updateLanguage(lang)
                    } label: {
                        Text(lang.displayName)
                    }
                }
            }
        }
    }

    private func meaningRowView(meaning: SharedWordMeaning, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(index).")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(meaning.definition)
                    .fontWeight(.semibold)

                Spacer()

                Menu {
                    Button {
                        Task {
                            try await play(meaning.definition)
                        }
                        AnalyticsService.shared.logEvent(.meaningPlayed)
                    } label: {
                        Label(Loc.Actions.listen, systemImage: "speaker.wave.2.fill")
                    }
                    .disabled(ttsPlayer.isPlaying)

                    if canEdit {
                        Button {
                            meaningToEdit = meaning
                            AnalyticsService.shared.logEvent(.wordExampleChangeButtonTapped)
                        } label: {
                            Label(Loc.Actions.edit, systemImage: "pencil")
                        }

                        Section {
                            Button(role: .destructive) {
                                deleteMeaning(meaning)
                                AnalyticsService.shared.logEvent(.wordExampleRemoved)
                            } label: {
                                Label(Loc.Actions.delete, systemImage: "trash")
                                    .tint(.red)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // Show examples for this meaning
            if !meaning.examples.isEmpty {
                ForEach(meaning.examples, id: \.self) { example in
                    HStack {
                        Text("•")
                            .foregroundColor(.secondary)
                        Menu {
                            Button {
                                Task {
                                    try await play(example)
                                }
                                AnalyticsService.shared.logEvent(.wordExamplePlayed)
                            } label: {
                                Label(Loc.Actions.listen, systemImage: "speaker.wave.2.fill")
                            }
                            .disabled(ttsPlayer.isPlaying)
                        } label: {
                            Text(example)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.leading, 20)
                }
            }
        }
        .padding(vertical: 12, horizontal: 16)
    }

    // MARK: - Collaborative Features Section

    private var collaborativeFeaturesSection: some View {
        CustomSectionView(
            header: Loc.SharedDictionaries.collaborativeFeatures,
            headerFontStyle: .stealth,
            footer: word.addedByDisplayText
        ) {
            VStack(spacing: 12) {
                // User's stats
                likeAndDifficultyControls

                // Stats summary
                statsSummary

                // View detailed stats button
                viewStatsButton
            }
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var likeAndDifficultyControls: some View {
        let userScore = word.getDifficultyFor(authenticationService.userEmail ?? "")
        let userDifficulty = Difficulty(score: userScore)

        HStack(spacing: 12) {
            StatSummaryCard(
                title: Loc.SharedDictionaries.yourScore,
                value: userScore.formatted(),
                icon: "trophy.fill"
            )

            StatSummaryCard(
                title: Loc.SharedDictionaries.yourStatus,
                value: userDifficulty.displayName,
                icon: userDifficulty.imageName
            )
        }
    }

    private var statsSummary: some View {
        HStack(spacing: 12) {
            StatSummaryCard(
                title: Loc.SharedDictionaries.averageScore,
                value: word.averageDifficulty.formatted(),
                icon: "chart.bar.fill"
            )

            StatSummaryCard(
                title: Loc.Analytics.totalRatings,
                value: word.difficulties.count.formatted(),
                icon: "person.2.fill"
            )
        }
    }

    private var viewStatsButton: some View {
        ActionButton(
            Loc.Analytics.viewDetailedStatistics,
            systemImage: "chart.bar.doc.horizontal"
        ) {
            showingDetailedStatistics = true
        }
    }

    // MARK: - Private Methods

    private func savePhonetic() {
        Task {
            var updatedWord = word
            updatedWord.phonetic = phoneticText
            await saveWordToFirebase(updatedWord)
        }
    }

    private func saveDefinition() {
        Task {
            var updatedWord = word
            // Update the primary meaning's definition
            if var primaryMeaning = updatedWord.primaryMeaning {
                primaryMeaning.definition = definitionText
                var meanings = updatedWord.meanings
                if let index = meanings.firstIndex(where: { $0.id == primaryMeaning.id }) {
                    meanings[index] = primaryMeaning
                    updatedWord = SharedWord(
                        id: updatedWord.id,
                        wordItself: updatedWord.wordItself,
                        meanings: meanings,
                        partOfSpeech: updatedWord.partOfSpeech,
                        phonetic: updatedWord.phonetic,
                        notes: updatedWord.notes,
                        languageCode: updatedWord.languageCode,
                        timestamp: updatedWord.timestamp,
                        updatedAt: Date(),
                        addedByEmail: updatedWord.addedByEmail,
                        addedByDisplayName: updatedWord.addedByDisplayName,
                        addedAt: updatedWord.addedAt,
                        likes: updatedWord.likes,
                        difficulties: updatedWord.difficulties
                    )
                }
            }
            await saveWordToFirebase(updatedWord)
        }
    }

    private func saveNotes() {
        Task {
            var updatedWord = word
            updatedWord.notes = notesText
            await saveWordToFirebase(updatedWord)
        }
    }

    private func saveWordToFirebase(_ updatedWord: SharedWord) async {
        do {
            // Update in-memory storage first
            await MainActor.run {
                if let index = dictionaryService.sharedWords[dictionaryId]?.firstIndex(where: {
                    $0.id == word.id
                }) {
                    dictionaryService.sharedWords[dictionaryId]?[index] = updatedWord
                }
                word = updatedWord
            }

            // Update Firebase directly with SharedWord
            try await dictionaryService.updateWordInSharedDictionary(dictionaryId: dictionaryId, sharedWord: updatedWord)
        } catch {
            errorReceived(title: Loc.Errors.updateFailed, error)
        }
    }

    private func play(
        _ text: String?,
        isWord: Bool = false
    ) async throws {
        guard let text else { return }
        try await ttsPlayer.play(
            text,
            languageCode: isWord ? word.languageCode : nil
        )
    }

    private func updatePartOfSpeech(_ value: PartOfSpeech) {
        Task {
            var updatedWord = word
            updatedWord.partOfSpeech = value.rawValue
            await saveWordToFirebase(updatedWord)
            AnalyticsService.shared.logEvent(.partOfSpeechChanged)
        }
    }

    private func updateLanguage(_ value: InputLanguage) {
        Task {
            var updatedWord = word
            updatedWord.languageCode = value.rawValue
            await saveWordToFirebase(updatedWord)
            AnalyticsService.shared.logEvent(.wordLanguageCodeChanged)
        }
    }

    private func addNewMeaning() {
        // Create a new meaning and add it to the word
        let newMeaning = SharedWordMeaning(
            definition: Loc.Words.newDefinition,
            examples: [],
            order: word.meanings.count
        )

        var updatedWord = word
        updatedWord.meanings.append(newMeaning)

        Task {
            await saveWordToFirebase(updatedWord)
        }
    }

    // MARK: - Collaborative Features Methods

    private func toggleLike() {
        Task {
            do {
                try await dictionaryService.toggleLike(for: word.id, in: dictionaryId)
            } catch {
                errorReceived(error)
            }
        }
    }

    private func showDeleteAlert() {
        AlertCenter.shared.showAlert(
            with: .deleteConfirmation(
                title: Loc.Words.deleteWord,
                message: "Are you sure you want to delete this word?",
                onCancel: {
                    AnalyticsService.shared.logEvent(.wordRemovingCanceled)
                },
                onDelete: {
                    deleteWord()
                    dismiss()
                }
            )
        )
    }

    private func deleteWord() {
        Task { @MainActor in
            do {
                try await dictionaryService.deleteWordFromSharedDictionary(
                    dictionaryId: dictionaryId,
                    wordId: word.id
                )
            } catch {
                errorReceived(title: Loc.Errors.deleteFailed, error)
            }
        }
    }

    private func errorReceived(title: String, _ error: Error) {
        AlertCenter.shared.showAlert(
            with: .info(
                title: title,
                message: error.localizedDescription
            )
        )
    }

    private func deleteMeaning(_ meaning: SharedWordMeaning) {
        AlertCenter.shared.showAlert(
            with: .deleteConfirmation(
                title: Loc.Words.deleteMeaning,
                message: Loc.Words.deleteMeaningConfirmation,
                onCancel: {
                    AnalyticsService.shared.logEvent(.meaningRemovingCanceled)
                },
                onDelete: {
                    var updatedWord = word
                    updatedWord.meanings.removeAll { $0.id == meaning.id }
                    Task {
                        await saveWordToFirebase(updatedWord)
                        AnalyticsService.shared.logEvent(.meaningRemoved)
                    }
                }
            )
        )
    }
}

// MARK: - StatSummaryCard

extension SharedWordDetailsView {
    struct StatSummaryCard: View {
        let title: String
        let value: String
        let icon: String

        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.accent)

                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .clippedWithPaddingAndBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
        }
    }
}

// MARK: - Hero Image Views

private extension SharedWordDetailsView {

    func heroImageView(image: Image) -> some View {
        GeometryReader { geometry in
            let offset = geometry.frame(in: .global).minY
            let height = max(200, 200 + offset)

            image
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: height)
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, Color.systemGroupedBackground]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100),
                    alignment: .bottom
                )
                .offset(y: offset > 0 ? -offset : 0)
                .frame(height: height)
        }
        .frame(height: 200)
    }
    
    @ViewBuilder
    var wordHeaderView: some View {
        Text(word.wordItself)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Image Related Views
    
    var imageSectionView: some View {
        CustomSectionView(header: Loc.WordImages.ImageSection.title, headerFontStyle: .stealth) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Loc.WordImages.ImageSection.noImageAddedYet)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(Loc.WordImages.ImageSection.addVisualRepresentation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        } trailingContent: {
            HeaderButton(Loc.WordImages.ImageSection.addImage, size: .small) {
                if ImagesOnboardingHelper.shouldShowOnboarding() {
                    showingImageOnboarding = true
                } else {
                    showingImageSelection = true
                }
            }
        }
    }
    
    var imagePremiumSectionView: some View {
        CustomSectionView(header: Loc.WordImages.ImageSection.title, headerFontStyle: .stealth) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Loc.WordImages.ImagePremium.dontMissOut)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(Loc.WordImages.ImagePremium.renewProStatus)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        } trailingContent: {
            HeaderButton(Loc.WordImages.ImagePremium.upgradeToPro, size: .small, style: .borderedProminent) {
                AnalyticsService.shared.logEvent(.imagePaywallShown, parameters: [
                    "trigger": "premium_image_access",
                    "word": word.wordItself,
                    "has_existing_image": hasImageAvailable
                ])
                paywallService.presentPaywall(for: .images) { didSubscribe in
                    if didSubscribe {
                        AnalyticsService.shared.logEvent(.imageUpgradeConversion, parameters: [
                            "conversion_source": "image_feature",
                            "previous_subscription_status": "free"
                        ])
                    }
                }
            }
        }
    }
    
    var removeImageButton: some View {
        Button(Loc.WordImages.ImageSection.removeImage) {
            AlertCenter.shared.showAlert(
                with: .deleteConfirmation(
                    title: Loc.WordImages.ImageSection.removeImage,
                    message: Loc.WordImages.ImageSection.removeImageDescription,
                    onDelete: {
                        word.imageUrl = nil
                        word.imageLocalPath = nil
                        image = nil
                    }
                )
            )
        }
        .foregroundStyle(.red)
    }
    
    func handleOnboardingCompletion() {
        // Check if user is premium
        if subscriptionService.isProUser {
            // User is premium, allow image selection
            showingImageSelection = true
        } else {
            // User is not premium, show paywall
            AnalyticsService.shared.logEvent(.imagePaywallShown, parameters: [
                "trigger": "onboarding_completion",
                "word": word.wordItself
            ])
            paywallService.presentPaywall(for: .images) { didSubscribe in
                if didSubscribe {
                    AnalyticsService.shared.logEvent(.imageUpgradeConversion, parameters: [
                        "conversion_source": "image_feature",
                        "previous_subscription_status": "free"
                    ])
                    // User subscribed, allow image selection
                    showingImageSelection = true
                }
                // If user didn't subscribe, do nothing (stay on word details)
            }
        }
    }
    
    func loadImage() async {
        // Check if image exists and set state with fallback
        if let imageLocalPath = word.imageLocalPath {
            shouldHaveNavigationTitle = !subscriptionService.isProUser

            print("🔍 [SharedWordDetails] Image path: \(imageLocalPath)")
            print("🌐 [SharedWordDetails] Image URL: \(word.imageUrl ?? "nil")")

            let result = await PexelsService.shared.getImageWithFallback(
                localPath: imageLocalPath,
                webUrl: word.imageUrl
            )

            await MainActor.run {
                if let image = result.image {
                    print("✅ [SharedWordDetails] Image loaded successfully (with fallback if needed)")
                    self.image = image

                    // Update the word with new relative path if fallback was used
                    if let newLocalPath = result.newLocalPath {
                        print("🔄 [SharedWordDetails] Updating with new relative path: \(newLocalPath)")
                        word.imageLocalPath = newLocalPath
                    }
                } else {
                    print("❌ [SharedWordDetails] Image failed to load even with fallback")
                    image = nil
                    shouldHaveNavigationTitle = true
                }
            }
        } else {
            print("🔍 [SharedWordDetails] No image path found")
            image = nil
            shouldHaveNavigationTitle = true
        }
    }
}
