import SwiftUI
import Combine
import Flow

struct WordDetailsView: View {

    @StateObject var word: CDWord
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ttsPlayer = TTSPlayer.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var paywallService = PaywallService.shared

    @FocusState private var isPhoneticsFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isNotesFocused: Bool
    @State private var showingTagSelection = false
    @State private var showingAddToSharedDictionary = false
    @State private var showingMeaningsList = false
    @State private var meaningToEdit: CDMeaning?
    @State private var image: Image?
    @State private var scrollOffset: CGFloat = .zero
    @State private var showingImageSelection = false
    @State private var showingImageOnboarding = false
    @State private var shouldHaveNavigationTitle: Bool = false

    var imageExists: Bool {
        (word.imageLocalPath != nil || image != nil) && subscriptionService.isProUser
    }
    
    var hasImageAvailable: Bool {
        word.imageLocalPath != nil || image != nil
    }

    init(word: CDWord) {
        self._word = StateObject(wrappedValue: word)
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
                    if !hasImageAvailable {
                        // Image Section (only show if no image exists)
                        imageSectionView
                    } else if hasImageAvailable && !subscriptionService.isProUser {
                        // Image Premium Section (show if image exists but user is not pro)
                        imagePremiumSectionView
                    }
                    
                    transcriptionSectionView
                    partOfSpeechSectionView
                    meaningsSectionView
                    notesSectionView
                    difficultySectionView
                    languageSectionView
                    tagsSectionView
                    
                    // Remove Image Button (only show if image exists and user is pro)
                    if hasImageAvailable && subscriptionService.isProUser {
                        removeImageButton
                    }
                }
                .padding(12)
                .animation(.default, value: word)
            }
        }
        .safeAreaInset(edge: .top) {
            Text(word.wordItself ?? "")
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .bold()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .padding(.top, 16)
                .background {
                    VStack(spacing: 0) {
                        Color.clear
                            .background(.thinMaterial)
                        Divider()
                    }
                    .opacity(shouldHaveNavigationTitle ? 1 : 0)
                }
                .opacity(shouldHaveNavigationTitle ? 1 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .groupedBackground()
        .navigationTitle(Loc.Navigation.wordDetails)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Shared Dictionaries button
                if AuthenticationService.shared.isSignedIn {
                    Button {
                        showingAddToSharedDictionary = true
                    } label: {
                        Image(systemName: "person.2.badge.plus")
                    }
                    .help(Loc.Words.addToSharedDictionary)
                    .hideIfOffline()
                    
                }

                // Favorite button
                Button {
                    word.isFavorite.toggle()
                    saveContext()
                    AnalyticsService.shared.logEvent(.wordFavoriteTapped)
                } label: {
                    Image(systemName: word.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(word.isFavorite ? .red : .primary)
                }
                .help(Loc.Actions.toggleFavorite)

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
        .sheet(isPresented: $showingTagSelection) {
            WordTagSelectionView(word: word)
        }
        .sheet(isPresented: $showingAddToSharedDictionary) {
            AddExistingWordToSharedView(word: word)
        }
        .sheet(isPresented: $showingMeaningsList) {
            MeaningsListView(word: word)
        }
        .sheet(item: $meaningToEdit) { meaning in
            MeaningEditView(meaning: meaning)
        }
        .sheet(isPresented: $showingImageSelection) {
            ImageSelectionView(
                word: word.wordItself ?? "",
                language: InputLanguage(rawValue: word.languageCode ?? "en") ?? .english,
                onImageSelected: { imageUrl, localPath in
                    word.imageUrl = imageUrl
                    word.imageLocalPath = localPath
                    // Update the image state
                    if let image = PexelsService.shared.getImageFromLocalPath(localPath) {
                        self.image = image
                        shouldHaveNavigationTitle = false
                    }
                    try? word.managedObjectContext?.save()
                },
                onDismiss: {
                    showingImageSelection = false
                }
            )
        }
        .imagesOnboarding(isPresented: $showingImageOnboarding, onCompleted: handleOnboardingCompletion)
        .task {
            await loadImage()
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
    }

    private var transcriptionSectionView: some View {
        CustomSectionView(
            header: Loc.Words.transcription,
            headerFontStyle: .stealth
        ) {
            TextField(
                Loc.Words.transcription,
                text: Binding(
                    get: { word.phonetic ?? "" },
                    set: { word.phonetic = $0 }
                ),
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .focused($isPhoneticsFocused)
            .fontWeight(.semibold)
        } trailingContent: {
            if isPhoneticsFocused {
                HeaderButton(Loc.Actions.done, size: .small) {
                    isPhoneticsFocused = false
                    saveContext()
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
        CustomSectionView(
            header: Loc.Words.partOfSpeech,
            headerFontStyle: .stealth
        ) {
            Text(PartOfSpeech(rawValue: word.partOfSpeech).displayName)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
        } trailingContent: {
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

    private var meaningsSectionView: some View {
        let meanings = word.meaningsArray
        let showLimited = meanings.count > 3
        let displayMeanings = showLimited ? Array(meanings.prefix(3)) : meanings
        
        return CustomSectionView(
            header: meanings.count > 1 ? "\(Loc.Words.meanings) (\(meanings.count))" : Loc.Words.meaning,
            headerFontStyle: .stealth,
            hPadding: .zero
        ) {
            if meanings.isEmpty {
                // Fallback to legacy definition if no meanings exist
                TextField(
                    Loc.Words.WordDetails.definition,
                    text: Binding(
                        get: { word.definition ?? "" },
                        set: { word.definition = $0 }
                    ),
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .focused($isDefinitionFocused)
                .fontWeight(.semibold)
                .padding(vertical: 12, horizontal: 16)
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
                        AnalyticsService.shared.logEvent(.wordDefinitionChanged)
                        saveContext()
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
                HeaderButton(icon: "plus", size: .small) {
                    addNewMeaning()
                }
            }
        }
    }

    private var notesSectionView: some View {
        CustomSectionView(
            header: Loc.Words.notes,
            headerFontStyle: .stealth
        ) {
            TextField(
                Loc.Words.addNotes,
                text: Binding(
                    get: { word.notes ?? "" },
                    set: { word.notes = $0 }
                ),
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .focused($isNotesFocused)
            .fontWeight(.semibold)
        } trailingContent: {
            if isNotesFocused {
                HeaderButton(Loc.Actions.done, size: .small) {
                    isNotesFocused = false
                    saveContext()
                }
            }
        }
    }

    private var difficultySectionView: some View {
        CustomSectionView(
            header: Loc.Words.difficulty,
            headerFontStyle: .stealth
        ) {
            let difficulty = word.difficultyLevel
            VStack(alignment: .leading, spacing: 4) {
                Label(difficulty.displayName, systemImage: difficulty.imageName)
                    .foregroundStyle(difficulty.color)
                    .fontWeight(.semibold)

                Text("\(Loc.Words.score): \(word.difficultyScore)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } trailingContent: {
            // Show info that difficulty can only be changed through quizzes
            Text(Loc.Words.quizBased)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var languageSectionView: some View {
        CustomSectionView(
            header: Loc.Words.language,
            headerFontStyle: .stealth
        ) {
            HStack {
                Text(word.languageDisplayName)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let languageCode = word.languageCode {
                    TagView(text: languageCode.uppercased(), color: .blue, size: .mini)
                }
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

    private var tagsSectionView: some View {
        CustomSectionView(
            header: Loc.Words.tags,
            headerFontStyle: .stealth
        ) {
            if word.tagsArray.isEmpty {
                Text(Loc.Words.noTagsAddedYet)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HFlow(alignment: .top, spacing: 8) {
                    ForEach(word.tagsArray) { tag in
                        HeaderButton(
                            tag.name.orEmpty,
                            color: tag.colorValue.color,
                            size: .small,
                            style: .borderedProminent,
                            action: {}
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } trailingContent: {
            HeaderButton(Loc.Tags.addTag, icon: "plus", size: .small) {
                showingTagSelection = true
            }
        }
    }



    // MARK: - Private Methods
    
    @ViewBuilder
    private func meaningRowView(meaning: CDMeaning, index: Int) -> some View {
        let definition = meaning.definition ?? Loc.Words.WordDetails.definition

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(index).")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(definition)
                    .fontWeight(.semibold)
                
                Spacer()

                Menu {
                    Button {
                        Task {
                            try await play(definition)
                        }
                        AnalyticsService.shared.logEvent(.meaningPlayed)
                    } label: {
                        Label(Loc.Actions.listen, systemImage: "speaker.wave.2.fill")
                    }
                    .disabled(ttsPlayer.isPlaying)
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
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            // Show examples for this meaning
            let examples = meaning.examplesDecoded
            if !examples.isEmpty {
                ForEach(Array(examples.enumerated()), id: \.offset) { _, example in
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
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.leading, 16)
                }
            }
        }
        .padding(vertical: 12, horizontal: 16)
    }

    private func addNewMeaning() {
        do {
            let _ = try word.addMeaning(definition: Loc.Words.newDefinition, examples: [])
            saveContext()
        } catch {
            errorReceived(error)
        }
    }

    private func saveContext() {
        Task {
            word.isSynced = false
            word.updatedAt = Date()

            do {
                try CoreDataService.shared.saveContext()
            } catch {
                errorReceived(error)
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
        word.partOfSpeech = value.rawValue
        saveContext()
        AnalyticsService.shared.logEvent(.partOfSpeechChanged)
    }

    private func updateLanguage(_ value: InputLanguage) {
        word.languageCode = value.rawValue
        saveContext()
        AnalyticsService.shared.logEvent(.wordLanguageCodeChanged)
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
        guard let id = word.id?.uuidString else { return }

        do {
            try WordsProvider.shared.delete(with: id)
        } catch {
            errorReceived(title: "Delete failed", error)
        }
    }

    private func removeTag(_ tag: CDTag) {
        try? TagService.shared.removeTagFromWord(tag, word: word)
        saveContext()
        AnalyticsService.shared.logEvent(.tagRemovedFromWord)
    }
    
    private func deleteMeaning(_ meaning: CDMeaning) {
        AlertCenter.shared.showAlert(
            with: .deleteConfirmation(
                title: Loc.Words.deleteMeaning,
                message: Loc.Words.deleteMeaningConfirmation,
                onCancel: {
                    AnalyticsService.shared.logEvent(.meaningRemovingCanceled)
                },
                onDelete: {
                    word.removeMeaning(meaning)
                    saveContext()
                    AnalyticsService.shared.logEvent(.meaningRemoved)
                }
            )
        )
    }
    
    // MARK: - Hero Image Views
    
    private func heroImageView(image: Image) -> some View {
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
    private var wordHeaderView: some View {
        if let wordItself = word.wordItself {
            Text(wordItself)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(!shouldHaveNavigationTitle ? 1 : 0)
        }
    }
    
    // MARK: - Image Related Views
    
    private var imageSectionView: some View {
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
    
    private var imagePremiumSectionView: some View {
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
            HeaderButton(Loc.WordImages.ImagePremium.upgradeToPro, size: .small) {
                AnalyticsService.shared.logEvent(.imagePaywallShown, parameters: [
                    "trigger": "premium_image_access",
                    "word": word.wordItself ?? "",
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
    
    private var removeImageButton: some View {
        HeaderButton(
            Loc.WordImages.ImageSection.removeImage,
            color: .red,
            size: .small,
            style: .bordered
        ) {
            AlertCenter.shared.showAlert(
                with: .deleteConfirmation(
                    title: Loc.WordImages.ImageSection.removeImage,
                    message: Loc.WordImages.ImageSection.removeImageDescription,
                    onDelete: {
                        // Delete the image file from documents directory
                        if let imageLocalPath = word.imageLocalPath {
                            try? PexelsService.shared.deleteImage(at: imageLocalPath)
                        }
                        word.imageUrl = nil
                        word.imageLocalPath = nil
                        image = nil
                        saveContext()
                    }
                )
            )
        }
    }
    
    private func handleOnboardingCompletion() {
        // Check if user is premium
        if subscriptionService.isProUser {
            // User is premium, allow image selection
            showingImageSelection = true
        } else {
            // User is not premium, show paywall
            AnalyticsService.shared.logEvent(.imagePaywallShown, parameters: [
                "trigger": "onboarding_completion",
                "word": word.wordItself ?? ""
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
    
    private func loadImage() async {
        // Check if image exists and set state with fallback
        if let imageLocalPath = word.imageLocalPath {
            shouldHaveNavigationTitle = !subscriptionService.isProUser

            print("🔍 [WordDetails] Image path: \(imageLocalPath)")
            print("🌐 [WordDetails] Image URL: \(word.imageUrl ?? "nil")")

            let result = await PexelsService.shared.getImageWithFallback(
                localPath: imageLocalPath,
                webUrl: word.imageUrl
            )

            await MainActor.run {
                if let image = result.image {
                    print("✅ [WordDetails] Image loaded successfully (with fallback if needed)")
                    self.image = image

                    // Update Core Data with new relative path if fallback was used
                    if let newLocalPath = result.newLocalPath {
                        print("🔄 [WordDetails] Updating Core Data with new relative path: \(newLocalPath)")
                        word.imageLocalPath = newLocalPath
                        saveContext()
                    }
                } else {
                    print("❌ [WordDetails] Image failed to load even with fallback")
                    image = nil
                    shouldHaveNavigationTitle = true
                }
            }
        } else {
            print("🔍 [WordDetails] No image path found")
            image = nil
            shouldHaveNavigationTitle = true
        }
    }
}
