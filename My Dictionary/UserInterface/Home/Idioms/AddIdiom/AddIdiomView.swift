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
            LazyVStack(spacing: 24) {
                idiomInputSectionView
                definitionInputSectionView
            }
            .padding(vertical: 12, horizontal: 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigation(
            title: "Add new idiom",
            mode: .inline,
            showsBackButton: true,
            trailingContent: {
                Button {
                    viewModel.handle(.save)
                } label: {
                    Text("Save")
                        .font(.system(.headline, design: .rounded))
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Capsule())
            }
        )
        .onReceive(viewModel.dismissPublisher) { _ in
            dismiss()
        }
    }

    private var idiomInputSectionView: some View {
        CustomSectionView(header: "Idiom") {
            TextField("Idiom", text: $viewModel.inputIdiom, axis: .vertical)
                .focused($isIdiomInputFocused)
                .clippedWithPaddingAndBackground()
        } trailingContent: {
            if isIdiomInputFocused {
                HeaderButton(text: "Done") {
                    isIdiomInputFocused = false
                }
            }
        }
    }

    private var definitionInputSectionView: some View {
        CustomSectionView(header: "Definition") {
            TextField("Definition", text: $viewModel.definitionField, axis: .vertical)
                .focused($isDefinitionInputFocused)
                .clippedWithPaddingAndBackground()
        } trailingContent: {
            if isDefinitionInputFocused {
                HeaderButton(text: "Done") {
                    isDefinitionInputFocused = false
                }
            }
        }
    }
}
