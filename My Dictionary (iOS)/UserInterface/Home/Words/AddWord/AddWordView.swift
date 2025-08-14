import SwiftUI

struct AddWordView: View {

    typealias ViewModel = AddWordViewModel

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ViewModel
    @State private var showingDictionarySelection = false
    @State private var selectedDictionaryId: String? = nil

    @StateObject private var authenticationService = AuthenticationService.shared

    init(viewModel: ViewModel, selectedDictionaryId: String? = nil) {
        self.viewModel = viewModel
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
            .padding(.horizontal, 16)
            .editModeDisabling()
        }
        .background {
            Color.systemGroupedBackground.ignoresSafeArea()
        }
        .navigation(
            title: "Add new word",
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                HeaderButton("Save", size: .medium, style: .borderedProminent) {
                    viewModel.handle(.saveToSharedDictionary(selectedDictionaryId))
                }
            },
            bottomContent: {
                if authenticationService.isSignedIn {
                    HeaderButton(
                        selectedDictionaryId == nil ? "Private Dictionary" : "Shared Dictionary",
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
        CellWrapper("Word") {
            CustomTextField("Type a word", text: $viewModel.inputWord, submitLabel: .search, axis: .horizontal) {
                if viewModel.inputWord.isNotEmpty {
                    viewModel.handle(.fetchData)
                }
            }
            .autocorrectionDisabled()
        }
    }
    
    var inputLanguageCellView: some View {
        CellWrapper("Input Language") {
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
        CellWrapper("Definition") {
            CustomTextField("Enter definition", text: $viewModel.descriptionField)
                .autocorrectionDisabled()
        }
    }

    @ViewBuilder
    var partOfSpeechCellView: some View {
        CellWrapper("Part of speech") {
            Menu {
                ForEach(PartOfSpeech.allCases, id: \.self) { partOfSpeech in
                    Button {
                        viewModel.handle(.selectPartOfSpeech(partOfSpeech))
                    } label: {
                        if viewModel.partOfSpeech == partOfSpeech {
                            Image(systemName: "checkmark")
                        }
                        Text(partOfSpeech.rawValue)
                    }
                }
            } label: {
                Text(viewModel.partOfSpeech?.rawValue ?? "Select a value")
            }
        }
    }

    @ViewBuilder
    var phoneticsCellView: some View {
        if let pronunciation = viewModel.pronunciation?.nilIfEmpty {
            CellWrapper("Pronunciation") {
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
        CellWrapper("Tags") {
            if viewModel.selectedTags.isEmpty {
                Text("No tags selected")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.selectedTags, id: \.id) { tag in
                            Menu {
                                Button("Remove", role: .destructive) {
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
        CustomSectionView(header: "Select a definition", hPadding: .zero) {
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
                            Text(GlobalConstant.isEnglishLanguage ? "Translating word..." : "Translating definitions...")
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
                    Text("There is an error loading definitions. Please try again.")
                } actions: {
                    HeaderButton("Retry", icon: "magnifyingglass", style: .borderedProminent) {
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
                            CellWrapper("Definition \(offset + 1), \(definition.partOfSpeech.rawValue)") {
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
                                    CellWrapper("Example") {
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
                    Text("Type a word and press 'Search' to find its definitions")
                } actions: {
                    HeaderButton("Search", icon: "magnifyingglass", style: .borderedProminent) {
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
