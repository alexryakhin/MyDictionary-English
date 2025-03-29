import SwiftUI
import Shared
import CoreUserInterface__macOS_

struct AddIdiomView: PageView {

    typealias ViewModel = AddIdiomViewModel

    @Environment(\.dismiss) var dismiss
    var viewModel: StateObject<AddIdiomViewModel>

    init(inputText: String) {
        viewModel = StateObject(wrappedValue: AddIdiomViewModel(inputText: inputText))
    }

    var contentView: some View {
        VStack {
            HStack {
                Text("Add new idiom").font(.title2).bold()
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                }
            }
            HStack {
                Text("IDIOM")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.top)
            TextField("Idiom", text: viewModel.projectedValue.inputText)
                .textFieldStyle(.roundedBorder)
            HStack {
                Text("DEFINITION")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.top)
            TextEditor(text: viewModel.projectedValue.inputDefinition)
                .padding(1)
                .background(Color.secondary.opacity(0.4))
            Button {
                viewModel.wrappedValue.addIdiom()
                dismiss()
            } label: {
                Text("Save")
                    .bold()
            }
        }
        .frame(width: 500, height: 300)
        .padding(16)
//        .alert(isPresented: viewModel.isShowingAlert) {
//            Alert(
//                title: Text("Ooops..."),
//                message: Text("You should enter an idiom and its definition before saving it"),
//                dismissButton: .default(Text("Got it"))
//            )
//        }
    }
}
