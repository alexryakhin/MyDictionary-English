import SwiftUI

struct AddWordView: View {

    typealias ViewModel = AddWordViewModel

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ViewModel
    @State private var showingDictionarySelection = false
    @State private var selectedDictionaryId: String? = nil

    init(viewModel: ViewModel, selectedDictionaryId: String? = nil) {
        self.viewModel = viewModel
        self._selectedDictionaryId = State(initialValue: selectedDictionaryId)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                FormWithDivider {
                    wordCellView
                    inputLanguageCellView
                    definitionCellView
                    partOfSpeechCellView
                    phoneticsCellView
                    tagsCellView
                }
                .clippedWithBackground()

                definitionsSectionView
            }
            .padding(.horizontal, 16)
            .editModeDisabling()
        }
        .background {
            Color(.systemGroupedBackground).ignoresSafeArea()
        }
        .navigation(
            title: "Add new word",
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                Button {
                    viewModel.handle(.saveToSharedDictionary(selectedDictionaryId))
                } label: {
                    Text("Save")
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Capsule())
            },
            bottomContent: {
                HStack {
                    Button {
                        showingDictionarySelection = true
                    } label: {
                        HStack {
                            Image(systemName: selectedDictionaryId == nil ? "person" : "person.2")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text(selectedDictionaryId == nil ? "Private Dictionary" : "Shared Dictionary")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .clipShape(Capsule())

                    Spacer()
                }
            }
        )
        .editModeDisabling()
        .onReceive(viewModel.dismissPublisher) { _ in
            dismiss()
        }
        .sheet(isPresented: $viewModel.showingTagSelection) {
            TagSelectionView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingDictionarySelection) {
            SharedDictionarySelectionView { dictionaryId in
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
                        .foregroundColor(.secondary)
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
        if let pronunciation = viewModel.pronunciation {
            CellWrapper("Pronunciation") {
                Text(pronunciation)
            } trailingContent: {
                Button {
                    viewModel.handle(.playInputWord)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    @ViewBuilder
    var tagsCellView: some View {
        CellWrapper("Tags") {
            if viewModel.selectedTags.isEmpty {
                Text("No tags selected")
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.selectedTags, id: \.id) { tag in
                            TagChip(tag: tag) {
                                viewModel.handle(.toggleTag(tag))
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        } trailingContent: {
            Button {
                viewModel.handle(.showTagSelection)
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    var definitionsSectionView: some View {
        CustomSectionView(header: "Select a definition") {
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
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
            case .error:
                ContentUnavailableView {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text("Error Loading Definitions")
                } description: {
                    Text("There is an error loading definitions. Please try again.")
                } actions: {
                    Button {
                        viewModel.handle(.fetchData)
                    } label: {
                        Label("Retry", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .clippedWithPaddingAndBackground()
            case .ready:
                let definitionsToShow = (!GlobalConstant.isEnglishLanguage && viewModel.translateDefinitions) ?
                    viewModel.translatedDefinitions : viewModel.definitions
                
                ForEach(Array(definitionsToShow.enumerated()), id: \.element.id) { offset, definition in
                    FormWithDivider {
                        CellWrapper("Definition \(offset + 1), \(definition.partOfSpeech.rawValue)") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(definition.text)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.primary)
                                
                                // Show original definition if translated (only for non-English locales)
                                if !GlobalConstant.isEnglishLanguage && viewModel.translateDefinitions && offset < viewModel.definitions.count {
                                    Text(viewModel.definitions[offset].text)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
                    .clippedWithBackground()
                }
            case .blank:
                ContentUnavailableView {
                    EmptyView()
                } description: {
                    Text("Type a word and press 'Search' to find its definitions")
                } actions: {
                    Button {
                        viewModel.handle(.fetchData)
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
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
        UIApplication.shared.endEditing()
        AnalyticsService.shared.logEvent(.definitionSelected)
    }
}

struct TagChip: View {
    let tag: CDTag
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tag.colorValue.color)
                .frame(width: 8, height: 8)
            
            Text(tag.name ?? "")
                .font(.caption)
                .fontWeight(.medium)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tag.colorValue.color.opacity(0.1))
        .clipShape(Capsule())
    }
}
