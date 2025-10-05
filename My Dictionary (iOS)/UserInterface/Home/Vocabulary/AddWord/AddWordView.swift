import SwiftUI

struct AddWordView: View {

    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: AddWordViewModel
    @State private var showingDictionarySelection = false
    @State private var selectedDictionaryId: String? = nil
    @State private var isSignInPresented = false
    @State private var showingImageOnboarding = false

    @StateObject private var paywallService = PaywallService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var authenticationService = AuthenticationService.shared
    @StateObject private var ttsPlayer = TTSPlayer.shared

    private let isWord: Bool

    init(input: String, selectedDictionaryId: String? = nil, isWord: Bool) {
        self._viewModel = .init(wrappedValue: .init(input: input, isWord: isWord))
        self._selectedDictionaryId = State(initialValue: selectedDictionaryId)
        self.isWord = isWord
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                FormWithDivider {
                    wordCellView
                    inputLanguageCellView
                    definitionCellView
                    partOfSpeechCellView
                    phoneticsCellView
                    imageCellView
                    // Only show tags for private words (not shared dictionary)
                    if selectedDictionaryId == nil {
                        tagsCellView
                    }
                }
                .clippedWithBackground()

                if isWord || viewModel.canUseAI {
                    definitionsSectionView
                        .hideIfOffline()
                }

                // AI Sign-in Required Banner (when not authenticated)
                if !authenticationService.isSignedIn {
                    BannerView.aiSignInRequired {
                        isSignInPresented = true
                    }
                    .hideIfOffline()
                } else {
                    // AI Usage Caption
                    aiUsageCaptionView
                        .hideIfOffline()
                    // AI Upgrade Banner (when limit reached)
                    if !viewModel.isProUser && !viewModel.canUseAI {
                        BannerView.aiUpgrade()
                            .hideIfOffline()
                    }
                }
            }
            .padding(vertical: 12, horizontal: 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .editModeDisabling()
        }
        .background {
            Color.systemGroupedBackground.ignoresSafeArea()
        }
        .navigation(
            title: isWord ? Loc.Words.addWord : Loc.Words.addIdiom,
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                HeaderButton(Loc.Actions.save, size: .medium, style: .borderedProminent) {
                    viewModel.handle(.saveToSharedDictionary(selectedDictionaryId))
                }
            },
            bottomContent: {
                if authenticationService.isSignedIn {
                    HeaderButton(
                        selectedDictionaryId == nil
                        ? Loc.Words.privateDictionary
                        : Loc.Words.sharedDictionary,
                        icon: selectedDictionaryId == nil ? "person" : "person.2",
                    ) {
                        showingDictionarySelection = true
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hideIfOffline()
                }
            }
        )
        .editModeDisabling()
        .onReceive(viewModel.dismissPublisher) { _ in
            dismiss()
        }
        .sheet(isPresented: $viewModel.showingTagSelection) {
            TagSelectionView(selectedTags: $viewModel.selectedTags)
        }
        .sheet(isPresented: $viewModel.showingImageSelection) {
            ImageSelectionView(
                word: viewModel.inputWord,
                language: viewModel.selectedInputLanguage,
                onImageSelected: { imageUrl, localPath in
                    viewModel.handle(.selectImage(imageUrl, localPath))
                },
                onDismiss: {
                    viewModel.showingImageSelection = false
                }
            )
        }
        .sheet(isPresented: $showingDictionarySelection) {
            SharedDictionarySelectionView(selectedDictionaryId: selectedDictionaryId) { dictionaryId in
                selectedDictionaryId = dictionaryId
            }
        }
        .sheet(isPresented: $isSignInPresented) {
            AuthenticationView(feature: .useAI)
        }
        .imagesOnboarding(isPresented: $showingImageOnboarding, onCompleted: handleOnboardingCompletion)
        .withPaywall()
    }

    // MARK: - Word

    var wordCellView: some View {
        CellWrapper(isWord ? Loc.Words.word : Loc.Words.idiom) {
            CustomTextField(
                isWord ? Loc.Words.typeWord : Loc.Words.idiom,
                text: $viewModel.inputWord,
                submitLabel: .search,
                axis: .horizontal
            ) {
                if viewModel.inputWord.isNotEmpty, (isWord || viewModel.canUseAI) {
                    viewModel.handle(.fetchData)
                }
            }
            .autocorrectionDisabled()
        }
    }

    // MARK: - Input language

    var inputLanguageCellView: some View {
        CellWrapper(Loc.Words.inputLanguage) {
            Menu {
                ForEach(InputLanguage.allCasesSorted, id: \.self) { language in
                    Button {
                        viewModel.handle(.selectInputLanguage(language))
                    } label: {
                        HStack {
                            Text(language.displayName)
                            if viewModel.selectedInputLanguage == language {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.selectedInputLanguage.displayName)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Definition

    var definitionCellView: some View {
        CellWrapper(Loc.Words.definition) {
            CustomTextField(Loc.Words.enterDefinition, text: $viewModel.descriptionField)
                .autocorrectionDisabled()
        }
    }

    // MARK: - Part of speech

    @ViewBuilder
    var partOfSpeechCellView: some View {
        CellWrapper(Loc.Words.partOfSpeech) {
            Menu {
                ForEach(isWord ? PartOfSpeech.wordCases : PartOfSpeech.expressionCases, id: \.self) { partOfSpeech in
                    Button {
                        viewModel.handle(.selectPartOfSpeech(partOfSpeech))
                    } label: {
                        if viewModel.partOfSpeech == partOfSpeech {
                            Image(systemName: "checkmark")
                        }
                        Text(partOfSpeech.displayName)
                    }
                }
            } label: {
                Text(viewModel.partOfSpeech?.displayName ?? Loc.Actions.selectValue)
            }
        }
    }

    // MARK: - Phonetics

    @ViewBuilder
    var phoneticsCellView: some View {
        if let pronunciation = viewModel.pronunciation?.nilIfEmpty {
            CellWrapper(Loc.Words.pronunciation) {
                Text(pronunciation)
            } trailingContent: {
                AsyncHeaderButton(
                    icon: "speaker.wave.2.fill",
                    size: .small
                ) {
                    try await viewModel.play(viewModel.inputWord)
                }
                .disabled(ttsPlayer.isPlaying)
            }
        }
    }

    // MARK: - Image Selection

    @ViewBuilder
    private var imageCellView: some View {
        CellWrapper(Loc.WordImages.ImageSection.title) {
            VStack(alignment: .leading, spacing: 12) {
                if let imageLocalPath = viewModel.selectedImageLocalPath,
                   let image = PexelsService.shared.getImageFromLocalPath(imageLocalPath) {
                    // Show selected image
                    HStack {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipped()
                            .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(Loc.WordImages.AddWordImage.selectedImage)
                            Text(Loc.WordImages.AddWordImage.tapToChange)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        HeaderButton(icon: "trash.fill", color: .red, size: .small) {
                            viewModel.handle(.selectImage("", ""))
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "photo")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(Loc.WordImages.AddWordImage.addImage)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }                }
            }
        } onTapAction: {
            if ImagesOnboardingHelper.shouldShowOnboarding() {
                showingImageOnboarding = true
            } else {
                viewModel.handle(.showImageSelection)
            }
        }
    }

    @ViewBuilder
    var tagsCellView: some View {
        CellWrapper(Loc.Words.tags) {
            if viewModel.selectedTags.isEmpty {
                Text(Loc.Words.noTagsSelected)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.selectedTags, id: \.id) { tag in
                            Menu {
                                Button(Loc.Actions.remove, role: .destructive) {
                                    viewModel.handle(.toggleTag(tag))
                                }
                                .tint(.red)
                            } label: {
                                TagView(
                                    text: tag.name.orEmpty,
                                    color: tag.colorValue.color,
                                    size: .small,
                                    style: .selected
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        } trailingContent: {
            HeaderButton(icon: "plus", size: .small) {
                viewModel.handle(.showTagSelection)
            }
        }
    }

    @ViewBuilder
    var definitionsSectionView: some View {
        CustomSectionView(header: Loc.Words.selectDefinition, hPadding: .zero) {
            switch viewModel.status {
            case .loading:
                if viewModel.isUsingAI {
                    AICircularProgressAnimation()
                        .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 16) {
                        LazyVStack {
                            ForEach(0..<3) { _ in
                                ShimmerView(height: 100)
                            }
                        }

                        if viewModel.isTranslating {
                            HStack {
                                LoaderView()
                                    .frame(width: 24, height: 24)
                                Text(GlobalConstant.isEnglishLanguage ? Loc.Words.translatingWord : Loc.Words.translatingDefinitions)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            case .error:
                ContentUnavailableView {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                } description: {
                    Text(Loc.Words.errorLoadingDefinitions)
                } actions: {
                    HeaderButton(Loc.Actions.retry, icon: "magnifyingglass", style: .borderedProminent) {
                        viewModel.handle(.fetchData)
                    }
                }
                .clippedWithPaddingAndBackground()
                .padding(.horizontal, 16)
            case .ready:
                // When using AI, always show the original definitions since AI provides them in the user's language
                // For traditional API, use translated definitions if available and needed
                let definitionsToShow = (!viewModel.translatedDefinitions.isEmpty && !GlobalConstant.isEnglishLanguage) ?
                viewModel.translatedDefinitions : viewModel.definitions

                FormWithDivider {
                    ForEach(Array(definitionsToShow.enumerated()), id: \.element.id) { offset, definition in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(Loc.Words.definition) \(offset + 1), \(definition.partOfSpeech.displayName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)

                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(definition.text)
                                        .multilineTextAlignment(.leading)
                                        .foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    // Show original definition if translated (only for non-English locales)
                                    if !GlobalConstant.isEnglishLanguage
                                        && offset < viewModel.definitions.count
                                        && viewModel.translatedDefinitions.isNotEmpty {
                                        Text(viewModel.definitions[offset].text)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .italic()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                multiSelectCheckboxImage(definition.id)
                                    .onTap {
                                        definitionToggled(definition, index: offset)
                                    }
                            }
                            .onTapGesture {
                                definitionToggled(definition, index: offset)
                            }

                            // Show examples from original definition
                            if offset < viewModel.definitions.count {
                                ForEach(viewModel.definitions[offset].examples, id: \.self) { example in
                                    HStack {
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        Menu {
                                            Button {
                                                Task {
                                                    try await viewModel.play(example)
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
                                }
                            }
                        }
                        .padding(vertical: 12, horizontal: 16)
                    }
                }
            case .blank:
                ContentUnavailableView {
                    EmptyView()
                } description: {
                    Text(Loc.Words.typeWordAndPressSearch)
                } actions: {
                    HeaderButton(Loc.Actions.search, icon: "magnifyingglass", style: .borderedProminent) {
                        viewModel.handle(.fetchData)
                    }
                }
                .clippedWithPaddingAndBackground()
            }
        }
    }

    @ViewBuilder
    private func multiSelectCheckboxImage(_ currentId: String) -> some View {
        let isSelected = viewModel.selectedDefinitions.contains { $0.id == currentId }
        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
            .frame(sideLength: 20)
    }

    private func definitionToggled(_ definition: WordDefinition, index: Int) {
        viewModel.handle(.toggleDefinition(definition))
        HapticManager.shared.triggerSelection()
        endEditing()
        AnalyticsService.shared.logEvent(.definitionSelected)
    }

    // MARK: - AI Usage Views

    @ViewBuilder
    private var aiUsageCaptionView: some View {
        if !viewModel.isProUser {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                Text(viewModel.aiRemainingRequests == 0 ?
                     Loc.Ai.AiUsage.unlimitedRequests :
                        Loc.Ai.AiUsage.remainingRequests(viewModel.aiRemainingRequests))
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Onboarding Completion Handler
    
    private func handleOnboardingCompletion() {
        // Check if user is premium
        if subscriptionService.isProUser {
            // User is premium, allow image selection
            viewModel.handle(.showImageSelection)
        } else {
            // User is not premium, show paywall
            AnalyticsService.shared.logEvent(.imagePaywallShown, parameters: [
                "trigger": "onboarding_completion",
                "word": viewModel.inputWord
            ])
            paywallService.presentPaywall(for: .images) { didSubscribe in
                if didSubscribe {
                    AnalyticsService.shared.logEvent(.imageUpgradeConversion, parameters: [
                        "conversion_source": "image_feature",
                        "previous_subscription_status": "free"
                    ])
                    // User subscribed, allow image selection
                    viewModel.handle(.showImageSelection)
                }
                // If user didn't subscribe, do nothing (stay on add word)
            }
        }
    }
}
