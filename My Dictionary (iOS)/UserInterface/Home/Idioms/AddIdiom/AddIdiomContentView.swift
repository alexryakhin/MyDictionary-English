import SwiftUI

struct AddIdiomContentView: View {

    @StateObject private var viewModel: AddIdiomViewModel

    init(inputIdiom: String = "") {
        self._viewModel = StateObject(wrappedValue: AddIdiomViewModel(inputIdiom: inputIdiom))
    }

    var body: some View {
        AddIdiomView(viewModel: viewModel)
    }
}
