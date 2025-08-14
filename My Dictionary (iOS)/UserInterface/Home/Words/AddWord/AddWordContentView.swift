import SwiftUI

struct AddWordContentView: View {

    @StateObject private var viewModel: AddWordViewModel
    private let selectedDictionaryId: String?

    init(inputWord: String = "", selectedDictionaryId: String? = nil) {
        self._viewModel = StateObject(wrappedValue: AddWordViewModel(inputWord: inputWord))
        self.selectedDictionaryId = selectedDictionaryId
    }

    var body: some View {
        AddWordView(viewModel: viewModel, selectedDictionaryId: selectedDictionaryId)
    }
}
