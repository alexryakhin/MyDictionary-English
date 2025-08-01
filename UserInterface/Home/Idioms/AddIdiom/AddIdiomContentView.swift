import SwiftUI

struct AddIdiomContentView: View {

    typealias ViewModel = AddIdiomViewModel

    @ObservedObject var viewModel: ViewModel
    @FocusState private var isIdiomInputFocused: Bool
    @FocusState private var isDefinitionInputFocused: Bool

    init(viewModel: AddIdiomViewModel) {
        self.viewModel = viewModel
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
            .background(Color.background)
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
        }
    }

    private var idiomInputSectionView: some View {
        CustomSectionView(header: "Idiom") {
            TextField("Idiom", text: $viewModel.inputIdiom, axis: .vertical)
                .focused($isIdiomInputFocused)
                .clippedWithPaddingAndBackground(.surface)
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
                .clippedWithPaddingAndBackground(.surface)
        } headerTrailingContent: {
            if isDefinitionInputFocused {
                SectionHeaderButton("Done") {
                    isDefinitionInputFocused = false
                }
            }
        }
    }
}
