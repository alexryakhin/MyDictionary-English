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

    private enum Constant {
        static let imageHeight: CGFloat = 280
        static let headerHeight: CGFloat = 200
    }

    @Environment(\.dismiss) private var dismiss

    @FocusState private var isPhoneticsFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isNotesFocused: Bool

    // Mutable state for editable fields
    @State private var phoneticText: String = ""
    @State private var definitionText: String = ""
    @State private var notesText: String = ""
    @State private var meaningToEdit: SharedWordMeaning?
    @State private var showingAllMeanings: Bool = false
    @State private var scrollOffset: CGFloat = .zero
    @State private var image: Image?
    @State private var shouldHaveNavigationTitle: Bool = false
    @State private var showingImageSelection = false
    @State private var showingImageOnboarding = false

    var imageExists: Bool {
        word.imageLocalPath != nil && image != nil
    }

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

    init(word: SharedWord, dictionaryId: String) {
        self._word = State(wrappedValue: word)
        self.dictionaryId = dictionaryId
        // Initialize mutable state with current word values
        self._phoneticText = State(wrappedValue: word.phonetic ?? "")
        self._definitionText = State(wrappedValue: word.definition)
        self._notesText = State(wrappedValue: word.notes ?? "")
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollViewWithReader(scrollOffset: $scrollOffset) {
                VStack(spacing: 0) {
                    // Hero Image Section
                    if let image {
                        heroImageView(image: image)
                    }

                    // Content
                    VStack(spacing: 16) {
                        // Word Header
                        wordHeaderView
                        
                        // Image Section (only show if no image exists and user can edit)
                        if !imageExists && canEdit {
                            imageSectionView
                        }
                        
                        // Content Sections
                        LazyVStack(spacing: 12) {
                            transcriptionSectionView
                            partOfSpeechSectionView
                            meaningsSectionView
                            notesSectionView
                            languageSectionView
                            collaborativeFeaturesSection
                            
                            // Remove Image Button (only show if image exists and user can edit)
                            if imageExists && canEdit {
                                removeImageButton
                            }
                        }
                    }
                    .if(isPad) { view in
                        view
                            .frame(maxWidth: 550, alignment: .center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(16)
                }
                .onChange(of: scrollOffset) { newValue in
                    let topOffset: CGFloat = !imageExists ? 70 : Constant.imageHeight + 30
                    withAnimation {
                        shouldHaveNavigationTitle = newValue <= -topOffset
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                SharedCustomNavigationBar(
                    title: word.wordItself,
                    isLiked: word.isLikedBy(authenticationService.userEmail ?? ""),
                    likeCount: word.likeCount,
                    canEdit: canEdit,
                    onLike: toggleLike,
                    onDelete: { showDeleteAlert() }
                )
                .opacity(shouldHaveNavigationTitle ? 1 : 0)
                .overlay {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.borderedProminent)
                        .clipShape(Capsule())

                        Spacer()

                        HStack(spacing: 4) {
                            if canEdit {
                                Button {
                                    showDeleteAlert()
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderedProminent)
                                .clipShape(Capsule())
                                .tint(.red)
                            }

                            Button {
                                toggleLike()
                            } label: {
                                Image(systemName: word.isLikedBy(authenticationService.userEmail ?? "") ? "heart.fill" : "heart")
                            }
                            .buttonStyle(.borderedProminent)
                            .clipShape(Capsule())
                            .tint(.red)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .opacity(!shouldHaveNavigationTitle ? 1 : 0)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .onAppear {
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
        .onDisappear {
            // Stop the real-time listener when leaving the view
            dictionaryService.stopSharedWordListener(dictionaryId: dictionaryId, wordId: word.id)
        }
        .sheet(item: $meaningToEdit) { meaning in
            SharedMeaningEditView(meaning: meaning, dictionaryId: dictionaryId, wordId: word.id)
        }
        .sheet(isPresented: $showingAllMeanings) {
            SharedMeaningsListView(word: $word, dictionaryId: dictionaryId)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showingImageSelection) {
            ImageSelectionView(
                word: word.wordItself,
                language: InputLanguage(rawValue: word.languageCode) ?? .english,
                onImageSelected: { imageUrl, localPath in
                    // Update the word with the new image
                    var updatedWord = word
                    updatedWord.imageUrl = imageUrl
                    updatedWord.imageLocalPath = localPath
                    
                    // Update the image state
                    if let image = PexelsService.shared.getImageFromLocalPath(localPath) {
                        self.image = image
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
        .withPaywall()
        .onAppear {
            // Check if image exists and set state with fallback
            if let imageLocalPath = word.imageLocalPath {
                print("🔍 [SharedWordDetails] Image path: \(imageLocalPath)")
                print("🌐 [SharedWordDetails] Image URL: \(word.imageUrl ?? "nil")")
                
                Task {
                    let result = await PexelsService.shared.getImageWithFallback(
                        localPath: imageLocalPath,
                        webUrl: word.imageUrl
                    )
                    
                    await MainActor.run {
                        if let image = result.image {
                            print("✅ [SharedWordDetails] Image loaded successfully (with fallback if needed)")
                            self.image = image

                            // Update Core Data with new relative path if fallback was used
                            if let newLocalPath = result.newLocalPath {
                                print("🔄 [SharedWordDetails] Updating Core Data with new relative path: \(newLocalPath)")
                                var updatedWord = word
                                updatedWord.imageLocalPath = newLocalPath
                                
                                Task {
                                    await saveWordToFirebase(updatedWord)
                                }
                            }
                        } else {
                            print("❌ [SharedWordDetails] Image failed to load even with fallback")
                            image = nil
                        }
                    }
                }
            } else {
                print("🔍 [SharedWordDetails] No image path found")
                image = nil
            }
        }
    }

    // MARK: - Hero Image View
    private func heroImageView(image: Image) -> some View {
        GeometryReader { geometry in
            let offset = geometry.frame(in: .global).minY
            let height = max(Constant.imageHeight, Constant.imageHeight + offset)

            image
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width, height: height)
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, Color(.systemGroupedBackground)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .offset(y: height - 100),
                    alignment: .bottom
                )
                .offset(y: offset > 0 ? -offset : 0)
                .frame(height: height)
        }
        .frame(height: Constant.imageHeight)
    }

    // MARK: - Word Header
    private var wordHeaderView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Part of Speech
            VStack(alignment: .leading, spacing: 8) {
                Text(word.wordItself)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 16) {
                    Text(word.partOfSpeech)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(Capsule())
                    
                    if word.isLikedBy(authenticationService.userEmail ?? "") {
                        Label("Liked", systemImage: "heart.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
            }
            
            // Quick Stats
            if let phonetic = word.phonetic, !phonetic.isEmpty {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundStyle(.accent)
                    Text(phonetic)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var imageSectionView: some View {
        CustomSectionView(header: Loc.WordImages.ImageSection.title, headerFontStyle: .stealth) {
            VStack(spacing: 12) {
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text(Loc.WordImages.ImageSection.noImageAddedYet)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(Loc.WordImages.ImageSection.addVisualRepresentation)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } trailingContent: {
            HeaderButton(Loc.WordImages.ImageSection.addImage, icon: "plus", size: .small) {
                if ImagesOnboardingHelper.shouldShowOnboarding() {
                    showingImageOnboarding = true
                } else {
                    showingImageSelection = true
                }
            }
        }
    }

    private var transcriptionSectionView: some View {
        CustomSectionView(header: Loc.Words.transcription, headerFontStyle: .stealth) {
            if canEdit {
                TextField(Loc.Words.transcription, text: $phoneticText, axis: .vertical)
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
                        showingAllMeanings = true
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
        CustomSectionView(header: Loc.Words.notes, headerFontStyle: .stealth) {
            if canEdit {
                TextField(Loc.Words.addNotes, text: $notesText, axis: .vertical)
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
    
    private var removeImageButton: some View {
        Button {
            removeImage()
        } label: {
            Text(Loc.WordImages.ImageSection.removeImage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 8)
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
            NavigationManager.shared.navigationPath.append(
                NavigationDestination.sharedWordDifficultyStats(
                    word: word
                )
            )
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

            HapticManager.shared.triggerNotification(type: .success)
        } catch {
            errorReceived(title: Loc.Errors.updateFailed, error)
        }
    }
    
    private func removeImage() {
        // Delete the image file from documents directory
        if let imageLocalPath = word.imageLocalPath {
            try? PexelsService.shared.deleteImage(at: imageLocalPath)
        }
        
        // Create updated word without image data
        var updatedWord = word
        updatedWord.imageUrl = nil
        updatedWord.imageLocalPath = nil
        
        // Clear the image state
        image = nil
        
        // Save changes to Firebase
        Task {
            await saveWordToFirebase(updatedWord)
        }
    }
    
    private func handleOnboardingCompletion() {
        // Check if user is premium
        if SubscriptionService.shared.isProUser {
            // User is premium, allow image selection
            showingImageSelection = true
        } else {
            // User is not premium, show paywall
            PaywallService.shared.presentPaywall(for: .images) { didSubscribe in
                if didSubscribe {
                    // User subscribed, allow image selection
                    showingImageSelection = true
                }
                // If user didn't subscribe, do nothing (stay on word details)
            }
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
                message: Loc.Words.deleteWordConfirmation,
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
                HapticManager.shared.triggerNotification(type: .success)
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

// MARK: - Supporting Views

struct SharedCustomNavigationBar: View {
    let title: String
    let isLiked: Bool
    let likeCount: Int
    let canEdit: Bool
    let onLike: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            .clipShape(Capsule())

            Spacer()
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
            
            HStack(spacing: 4) {
                if canEdit {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .clipShape(Capsule())
                    .tint(.red)
                }

                Button(action: onLike) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .animation(.easeInOut(duration: 0.3), value: true)
    }
}
