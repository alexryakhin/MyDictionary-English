import SwiftUI

struct AddIdiomView: View {

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AddIdiomViewModel
    @FocusState private var isIdiomInputFocused: Bool
    @FocusState private var isDefinitionInputFocused: Bool

    init(viewModel: AddIdiomViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                idiomInputSectionView
                definitionInputSectionView
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
        .navigation(
            title: Loc.Idioms.addNewIdiom.localized,
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                HeaderButton(Loc.Actions.save.localized, size: .medium) {
                    viewModel.handle(.save)
                }
            }
        )
        .onReceive(viewModel.dismissPublisher) { _ in
            dismiss()
        }
    }

    private var idiomInputSectionView: some View {
        CustomSectionView(header: Loc.Idioms.idiom.localized) {
            TextField(Loc.Idioms.idiom.localized, text: $viewModel.inputIdiom, axis: .vertical)
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
