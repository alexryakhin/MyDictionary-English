import SwiftUI

struct AddIdiomView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddIdiomViewModel
    @FocusState private var isIdiomInputFocused: Bool
    @FocusState private var isDefinitionInputFocused: Bool

    init(inputIdiom: String) {
        self._viewModel = .init(wrappedValue: .init(inputIdiom: inputIdiom))
    }

    var body: some View {
        ScrollViewWithCustomNavBar {
            LazyVStack(spacing: 12) {
                idiomInputSectionView
                definitionInputSectionView
            }
            .padding(12)
        } navigationBar: {
            NavigationBarView(
                title: Loc.Idioms.addNewIdiom.localized,
                trailingContent: {
                    HeaderButton(Loc.Actions.save.localized, style: .borderedProminent) {
                        viewModel.handle(.save)
                    }
                    .help(Loc.Actions.save.localized)
                }
            )
        }
        .groupedBackground()
        .onReceive(viewModel.dismissPublisher) { _ in
            dismiss()
        }
    }

    private var idiomInputSectionView: some View {
        CustomSectionView(header: Loc.Idioms.idiom.localized) {
            TextField(Loc.Idioms.idiom.localized, text: $viewModel.inputIdiom, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isIdiomInputFocused)
                .clippedWithPaddingAndBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 12)
        } trailingContent: {
            if isIdiomInputFocused {
                HeaderButton(Loc.Actions.done.localized, size: .small) {
                    isIdiomInputFocused = false
                }
            }
        }
    }

    private var definitionInputSectionView: some View {
        CustomSectionView(header: Loc.Words.definition.localized) {
            TextField(Loc.Words.definition.localized, text: $viewModel.definitionField, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isDefinitionInputFocused)
                .clippedWithPaddingAndBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 12)
        } trailingContent: {
            if isDefinitionInputFocused {
                HeaderButton(Loc.Actions.done.localized, size: .small) {
                    isDefinitionInputFocused = false
                }
            }
        }
    }
}
