import SwiftUI

struct AddIdiomView: View {

    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = AddIdiomViewModel()
    @FocusState private var isIdiomInputFocused: Bool
    @FocusState private var isDefinitionInputFocused: Bool

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                idiomInputSectionView
                definitionInputSectionView
            }
            .padding(12)
        }
        .groupedBackground()
        .navigationTitle("Add new idiom")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Close button
                Button("Close") {
                    dismiss()
                }
                .help("Close Add Idiom")
                
                // Save button
                Button("Save") {
                    viewModel.handle(.save)
                }
                .buttonStyle(.borderedProminent)
                .help("Save Idiom")
            }
        }
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
