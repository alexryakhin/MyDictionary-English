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
                title: "Add new idiom",
                trailingContent: {
                    HeaderButton("Save", style: .borderedProminent) {
                        viewModel.handle(.save)
                    }
                    .help("Save Idiom")
                }
            )
        }
        .groupedBackground()
        .onReceive(viewModel.dismissPublisher) { _ in
            dismiss()
        }
    }

    private var idiomInputSectionView: some View {
        CustomSectionView(header: "Idiom") {
            TextField("Idiom", text: $viewModel.inputIdiom, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isIdiomInputFocused)
                .clippedWithPaddingAndBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 12)
        } trailingContent: {
            if isIdiomInputFocused {
                HeaderButton("Done", size: .small) {
                    isIdiomInputFocused = false
                }
            }
        }
    }

    private var definitionInputSectionView: some View {
        CustomSectionView(header: "Definition") {
            TextField("Definition", text: $viewModel.definitionField, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isDefinitionInputFocused)
                .clippedWithPaddingAndBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 12)
        } trailingContent: {
            if isDefinitionInputFocused {
                HeaderButton("Done", size: .small) {
                    isDefinitionInputFocused = false
                }
            }
        }
    }
}
