import SwiftUI

struct AddWordView: View {

    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: AddWordViewModel
    @State private var showingDictionarySelection = false
    @State private var selectedDictionaryId: String? = nil

    @StateObject private var authenticationService = AuthenticationService.shared

    init(inputWord: String, selectedDictionaryId: String? = nil) {
        self._viewModel = .init(wrappedValue: .init(inputWord: inputWord))
        self._selectedDictionaryId = State(initialValue: selectedDictionaryId)
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
                    // Only show tags for private words (not shared dictionary)
                    if selectedDictionaryId == nil {
                        tagsCellView
                    }
                }
                .clippedWithBackground()

                definitionsSectionView
            }
            .padding(16)
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
            title: Loc.Words.addNewWord.localized,
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                HeaderButton(Loc.Actions.save.localized, size: .medium, style: .borderedProminent) {
                    viewModel.handle(.saveToSharedDictionary(selectedDictionaryId))
                }
            },
            bottomContent: {
                if authenticationService.isSignedIn {
                    HeaderButton(
                        selectedDictionaryId == nil
                        ? Loc.Words.privateDictionary.localized
                        : Loc.Words.sharedDictionary.localized,
                        icon: selectedDictionaryId == nil ? "person" : "person.2",
                    ) {
                        showingDictionarySelection = true
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        .sheet(isPresented: $showingDictionarySelection) {
            SharedDictionarySelectionView(selectedDictionaryId: selectedDictionaryId) { dictionaryId in
                selectedDictionaryId = dictionaryId
            }
        }
    }

    var wordCellView: some View {
        CellWrapper(Loc.Words.word.localized) {
            CustomTextField(Loc.Words.typeWord.localized, text: $viewModel.inputWord, submitLabel: .search, axis: .horizontal) {
                if viewModel.inputWord.isNotEmpty {
                    viewModel.handle(.fetchData)
                }
            }
            .autocorrectionDisabled()
        }
    }

    var inputLanguageCellView: some View {
        CellWrapper(Loc.Words.inputLanguage.localized) {
            Menu {
                ForEach(InputLanguage.allCases, id: \.self) { language in
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

    var definitionCellView: some View {
        CellWrapper(Loc.Words.definition.localized) {
            CustomTextField(Loc.App.enterDefinition.localized, text: $viewModel.descriptionField)
                .autocorrectionDisabled()
        }
    }

    @ViewBuilder
    var partOfSpeechCellView: some View {
        CellWrapper(Loc.Words.partOfSpeech.localized) {
            Menu {
                ForEach(PartOfSpeech.allCases, id: \.self) { partOfSpeech in
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
                Text(viewModel.partOfSpeech?.displayName ?? Loc.App.selectValue.localized)
            }
        }
    }

    @ViewBuilder
    var phoneticsCellView: some View {
        if let pronunciation = viewModel.pronunciation?.nilIfEmpty {
            CellWrapper(Loc.App.pronunciation.localized) {
                Text(pronunciation)
            } trailingContent: {
                HeaderButton(icon: "speaker.wave.2.fill", size: .small) {
                    viewModel.handle(.playInputWord)
                }
            }
        }
    }

    @ViewBuilder
    var tagsCellView: some View {
        CellWrapper(Loc.App.tags.localized) {
            if viewModel.selectedTags.isEmpty {
                Text(Loc.Words.noTagsSelected.localized)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.selectedTags, id: \.id) { tag in
                            Menu {
                                Button(Loc.Actions.remove.localized, role: .destructive) {
                                    viewModel.handle(.toggleTag(tag))
                                }
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
        CustomSectionView(header: Loc.App.selectDefinition.localized, hPadding: .zero) {
            switch viewModel.status {
            case .loading:
                VStack(spacing: 16) {
                    LazyVStack {
                        ForEach(0..<3) { _ in
                            ShimmerView(height: 100)
                        }
                    }

                    if viewModel.isTranslating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(GlobalConstant.isEnglishLanguage ? Loc.App.translatingWord.localized : Loc.App.translatingDefinitions.localized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 16)
            case .error:
                ContentUnavailableView {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                } description: {
                    Text(Loc.Words.errorLoadingDefinitions.localized)
                } actions: {
                    HeaderButton(Loc.App.retry.localized, icon: "magnifyingglass", style: .borderedProminent) {
                        viewModel.handle(.fetchData)
                    }
                }
                .clippedWithPaddingAndBackground()
                .padding(.horizontal, 16)
            case .ready:
                let definitionsToShow = (!GlobalConstant.isEnglishLanguage && viewModel.translateDefinitions) ?
                viewModel.translatedDefinitions : viewModel.definitions

                FormWithDivider {
                    ForEach(Array(definitionsToShow.enumerated()), id: \.element.id) { offset, definition in
                        FormWithDivider {
                            CellWrapper("\(Loc.Words.definition.localized) \(offset + 1), \(definition.partOfSpeech.displayName)") {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(definition.text)
                                        .multilineTextAlignment(.leading)
                                        .foregroundStyle(.primary)

                                    // Show original definition if translated (only for non-English locales)
                                    if !GlobalConstant.isEnglishLanguage && viewModel.translateDefinitions && offset < viewModel.definitions.count {
                                        Text(viewModel.definitions[offset].text)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .italic()
                                    }
                                }
                            } trailingContent: {
                                checkboxImage(definition.id)
                                    .onTap {
                                        definitionSelected(definition, index: offset)
                                    }
                            }
                            .onTapGesture {
                                definitionSelected(definition, index: offset)
                            }

                            // Show examples from original definition
                            if offset < viewModel.definitions.count {
                                ForEach(viewModel.definitions[offset].examples, id: \.self) { example in
                                    CellWrapper(Loc.App.example.localized) {
                                        Text(example)
                                    }
                                }
                            }
                        }
                    }
                }
            case .blank:
                ContentUnavailableView {
                    EmptyView()
                } description: {
                    Text(Loc.Words.typeWordAndPressSearch.localized)
                } actions: {
                    HeaderButton(Loc.Actions.search.localized, icon: "magnifyingglass", style: .borderedProminent) {
                        viewModel.handle(.fetchData)
                    }
                }
                .clippedWithPaddingAndBackground()
            }
        }
    }

    @ViewBuilder
    private func checkboxImage(_ currentId: String) -> some View {
        let isSelected = currentId == viewModel.selectedDefinition?.id
        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
            .frame(sideLength: 20)
    }

    private func definitionSelected(_ definition: WordDefinition, index: Int) {
        viewModel.handle(.selectDefinition(definition))
        HapticManager.shared.triggerSelection()
        endEditing()
        AnalyticsService.shared.logEvent(.definitionSelected)
    }
}
