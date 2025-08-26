import SwiftUI

struct AddIdiomView: View {

    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AddIdiomViewModel

    @StateObject private var authenticationService = AuthenticationService.shared

    init(inputIdiom: String) {
        self._viewModel = .init(wrappedValue: .init(inputIdiom: inputIdiom))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                FormWithDivider {
                    idiomCellView
                    inputLanguageCellView
                    definitionCellView
                    tagsCellView
                }
                .clippedWithBackground()
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
            title: Loc.Words.addNewIdiom,
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                HeaderButton(Loc.Actions.save, size: .medium, style: .borderedProminent) {
                    viewModel.handle(.save)
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
    }

    var idiomCellView: some View {
        CellWrapper(Loc.Words.idiom) {
            CustomTextField(Loc.Words.typeWordHere, text: $viewModel.inputIdiom, submitLabel: .done, axis: .horizontal)
                .autocorrectionDisabled()
        }
    }

    var inputLanguageCellView: some View {
        CellWrapper(Loc.Words.inputLanguage) {
            Menu {
                ForEach(InputLanguage.allCases.filter { $0 != .auto }, id: \.self) { language in
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
        CellWrapper(Loc.Words.definition) {
            CustomTextField(Loc.Words.enterDefinition, text: $viewModel.definitionField, axis: .vertical)
                .autocorrectionDisabled()
        }
    }

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
}
