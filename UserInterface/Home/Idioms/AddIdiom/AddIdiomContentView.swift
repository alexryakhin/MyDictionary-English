import SwiftUI
import CoreUserInterface
import CoreNavigation
import Core

public struct AddIdiomContentView: PageView {

    public typealias ViewModel = AddIdiomViewModel

    @ObservedObject public var viewModel: ViewModel

    public init(viewModel: AddIdiomViewModel) {
        self.viewModel = viewModel
    }

    public var contentView: some View {
        NavigationView {
            List {
                Section {
                    TextField("Idiom", text: $viewModel.inputIdiom)
                } header: {
                    Text("Idiom")
                }
                Section {
                    TextEditor(text: $viewModel.descriptionField)
                        .frame(height: 200)
                } header: {
                    Text("Definition")
                }
            }
            .editModeDisabling()
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
}
