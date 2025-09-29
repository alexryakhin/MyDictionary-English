import SwiftUI
import Combine
import Flow

struct WordDetailsContentView: View {

    private enum Constant {
        static let imageHeight: CGFloat = 200
        static let headerHeight: CGFloat = 200
    }

    @StateObject var word: CDWord
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ttsPlayer = TTSPlayer.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var paywallService = PaywallService.shared

    @FocusState private var isPhoneticsFocused: Bool
    @FocusState private var isDefinitionFocused: Bool
    @FocusState private var isNotesFocused: Bool
    @State private var showingTagSelection = false
    @State private var meaningToEdit: CDMeaning?
    @State private var scrollOffset: CGFloat = .zero
    @State private var image: Image?
    @State private var shouldHaveNavigationTitle: Bool = false
    @State private var showingImageSelection = false
    @State private var showingImageOnboarding = false

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
                                .padding(.horizontal, 28)
                                .padding(.bottom, 12)
                                .if(isPad) { view in
                                    view
                                        .frame(maxWidth: 600, alignment: .center)
                                }
                        }
                }

                // Content Sections
                LazyVStack(spacing: 12) {
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
                .if(isPad) { view in
                    view
                        .frame(maxWidth: 550, alignment: .center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: scrollOffset) { newValue in
                guard hasImageAvailable && subscriptionService.isProUser else {
                    shouldHaveNavigationTitle = true
                    return
                }
                let topOffset: CGFloat = Constant.imageHeight
                withAnimation {
                    shouldHaveNavigationTitle = newValue <= -topOffset
                }
            }
        }
        .safeAreaInset(edge: .top) {
            CustomNavigationBar(
                title: word.wordItself ?? "",
                isFavorite: word.isFavorite,
                onFavorite: {
                    word.isFavorite.toggle()
                    saveContext()
                    AnalyticsService.shared.logEvent(.wordFavoriteTapped)
                },
                onDelete: { showDeleteAlert() }
            )
            .opacity(shouldHaveNavigationTitle ? 1 : 0)
            .overlay(alignment: .top) {
                HStack {
                    HeaderButton(icon: "chevron.left") {
                        dismiss()
                    }
                    .background(in: .capsule)

                    Spacer()

                    HStack(spacing: 4) {
                        HeaderButton(
                            icon: "trash",
                            color: .red,
                        ) {
                            showDeleteAlert()
                        }
                        .background(in: .capsule)
                        HeaderButton(
                            icon: word.isFavorite ? "heart.fill" : "heart",
                        ) {
                            word.isFavorite.toggle()
                            saveContext()
                            AnalyticsService.shared.logEvent(.wordFavoriteTapped)
                        }
                        .background(in: .capsule)
                    }
                }
                .padding(vertical: 12, horizontal: 16)
                .opacity(!shouldHaveNavigationTitle ? 1 : 0)
                .padding(12)
                .if(isPad) { view in
                    view
                        .frame(maxWidth: 600, alignment: .center)
                }
            }
        }
        .groupedBackground()
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingTagSelection) {
            WordTagSelectionView(word: word)
        }
        .sheet(item: $meaningToEdit) { meaning in
            MeaningEditView(meaning: meaning)
        }
        .sheet(isPresented: $showingImageSelection) {
            ImageSelectionView(
                word: word.wordItself ?? "",
                language: InputLanguage(rawValue: word.languageCode ?? "en") ?? .english,
                onImageSelected: { imageUrl, localPath in
                    // Update the word with the new image
                    word.imageUrl = imageUrl
                    word.imageLocalPath = localPath

                    // Update the image state
                    if let image = PexelsService.shared.getImageFromLocalPath(localPath) {
                        self.image = image
                        shouldHaveNavigationTitle = false
                    }

                    saveContext()
                },
                onDismiss: {
                    showingImageSelection = false
                }
            )
        }
        .imagesOnboarding(isPresented: $showingImageOnboarding, onCompleted: handleOnboardingCompletion)
        .withPaywall()
        .task {
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

    // MARK: - Hero Image View
    private func heroImageView(image: Image) -> some View {
        GeometryReader { geometry in
            let offset = geometry.frame(in: .global).minY
            let height = max(Constant.imageHeight, Constant.imageHeight + offset)

            image
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: height)
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                Color.systemGroupedBackground.opacity(0),
                                Color.systemGroupedBackground.opacity(0.5),
                                Color.systemGroupedBackground
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100),
                    alignment: .bottom
                )
                .offset(y: offset > 0 ? -offset : 0)
                .frame(height: height)
        }
        .frame(height: Constant.imageHeight)
    }

    // MARK: - Word Header
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

    private var imageSectionView: some View {
        CustomSectionView(header: Loc.WordImages.ImageSection.title, headerFontStyle: .stealth) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Loc.WordImages.ImageSection.noImageAddedYet)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(Loc.WordImages.ImageSection.addVisualRepresentation)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        } trailingContent: {
            HeaderButton(Loc.WordImages.ImageSection.addImage, icon: "photo", size: .small) {
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
            HeaderButton(Loc.WordImages.ImagePremium.upgradeToPro, size: .small, style: .borderedProminent) {
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

    private var transcriptionSectionView: some View {
        CustomSectionView(header: Loc.Words.WordDetails.transcription, headerFontStyle: .stealth) {
            TextField(Loc.Words.WordDetails.transcription, text: Binding(
                get: { word.phonetic ?? "" },
                set: { word.phonetic = $0 }
            ), axis: .vertical)
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
        CustomSectionView(header: Loc.Words.WordDetails.partOfSpeech, headerFontStyle: .stealth) {
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
                TextField(Loc.Words.WordDetails.definition, text: Binding(
                    get: { word.definition ?? "" },
                    set: { word.definition = $0 }
                ), axis: .vertical)
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
                        NavigationManager.shared.navigate(to: .wordMeaningsList(word))
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
        CustomSectionView(header: Loc.Words.notes, headerFontStyle: .stealth) {
            TextField(Loc.Words.addNotes, text: Binding(
                get: { word.notes ?? "" },
                set: { word.notes = $0 }
            ), axis: .vertical)
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
        CustomSectionView(header: Loc.Words.WordDetails.difficulty, headerFontStyle: .stealth) {
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
        CustomSectionView(header: Loc.Words.language, headerFontStyle: .stealth) {
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
        CustomSectionView(header: Loc.Words.tags, headerFontStyle: .stealth) {
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
            HeaderButton(Loc.Words.addTag, icon: "plus", size: .small) {
                showingTagSelection = true
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
            removeImage()
        }
        .padding(.top, 8)
    }

    // MARK: - Private Methods

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
    
    private func removeImage() {
        AlertCenter.shared.showAlert(
            with: .deleteConfirmation(
                title: Loc.WordImages.ImageSection.removeImage,
                message: Loc.WordImages.ImageSection.removeImageDescription,
                onDelete: {
                    // Delete the image file from documents directory
                    if let imageLocalPath = word.imageLocalPath {
                        try? PexelsService.shared.deleteImage(at: imageLocalPath)
                    }

                    // Clear image data from Core Data
                    word.imageUrl = nil
                    word.imageLocalPath = nil

                    // Clear the image state
                    image = nil

                    // Save changes
                    saveContext()
                }
            )
        )
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

    @ViewBuilder
    private func meaningRowView(meaning: CDMeaning, index: Int) -> some View {
        let definition = meaning.definition ?? Loc.Words.definition

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
            errorReceived(title: Loc.Words.WordDetails.deleteFailed, error)
        }
    }

    private func removeTag(_ tag: CDTag) {
        try? TagService.shared.removeTagFromWord(tag, word: word)
        saveContext()
        AnalyticsService.shared.logEvent(.tagRemovedFromWord)
    }

    private func editMeaning(_ meaning: CDMeaning) {
        meaningToEdit = meaning
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
}

// MARK: - Supporting Views

struct CustomNavigationBar: View {
    let title: String
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HeaderButton(icon: "chevron.left") {
                    dismiss()
                }

                Text(Loc.Words.wordDetails)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 4) {
                    HeaderButton(
                        icon: "trash",
                        color: .red,
                        action: onDelete
                    )
                    HeaderButton(
                        icon: isFavorite ? "heart.fill" : "heart",
                        action: onFavorite
                    )
                }
            }

            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(vertical: 12, horizontal: 16)
        .glassBackgroundEffectIfAvailable(.regular, in: RoundedRectangle(cornerRadius: 32))
        .if(isGlassAvailable == false) {
            $0
                .clippedWithBackgroundMaterial(.ultraThinMaterial, cornerRadius: 32)
                .shadow(radius: 2)
        }
        .padding(12)
        .animation(.easeInOut(duration: 0.3), value: true)
        .if(isPad) { view in
            view
                .frame(maxWidth: 600, alignment: .center)
        }
    }
}
