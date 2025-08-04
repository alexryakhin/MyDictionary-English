import SwiftUI

struct AddIdiomContentView: View {

    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: AddIdiomViewModel
    @FocusState private var isIdiomInputFocused: Bool
    @FocusState private var isDefinitionInputFocused: Bool

    init(inputIdiom: String = "") {
        self._viewModel = StateObject(wrappedValue: AddIdiomViewModel(inputIdiom: inputIdiom))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    idiomInputSectionView
                    definitionInputSectionView
                }
                .padding(vertical: 12, horizontal: 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitle("Add new idiom")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.handle(.save)
                    } label: {
                        Text("Save")
                            .font(.system(.headline, design: .rounded))
                    }
                }
            }
            .onReceive(viewModel.dismissPublisher) { _ in
                dismiss()
            }
        }
    }

    private var idiomInputSectionView: some View {
        CustomSectionView(header: "Idiom") {
            TextField("Idiom", text: $viewModel.inputIdiom, axis: .vertical)
                .focused($isIdiomInputFocused)
                .clippedWithPaddingAndBackground()
        } headerTrailingContent: {
            if isIdiomInputFocused {
                SectionHeaderButton("Done") {
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
        } headerTrailingContent: {
            if isDefinitionInputFocused {
                SectionHeaderButton("Done") {
                    isDefinitionInputFocused = false
                }
            }
        }
    }
}
