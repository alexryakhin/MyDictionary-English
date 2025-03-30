import SwiftUI
import Shared
import CoreUserInterface__macOS_

struct AddIdiomView: PageView {

    @Environment(\.dismiss) var dismiss

    typealias ViewModel = AddIdiomViewModel

    var _viewModel: StateObject<ViewModel>
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    init(inputText: String) {
        _viewModel = StateObject(wrappedValue: ViewModel(inputText: inputText))
    }

    var contentView: some View {
        ScrollViewWithCustomNavBar {
            VStack(spacing: 16) {
                CustomSectionView(header: "Idiom") {
                    TextField("Idiom", text: _viewModel.projectedValue.inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .clippedWithPaddingAndBackground(.textBackgroundColor)
                }
                CustomSectionView(header: "Definition") {
                    TextField("Definition", text: _viewModel.projectedValue.inputDefinition, axis: .vertical)
                        .textFieldStyle(.plain)
                        .clippedWithPaddingAndBackground(.textBackgroundColor)
                }
            }
            .padding(vertical: 12, horizontal: 16)
        } navigationBar: {
            HStack(spacing: 12) {
                Text("Add new idiom")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.app.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderless)
            }
            .padding(vertical: 12, horizontal: 16)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                viewModel.addIdiom()
            } label: {
                Label("Save", systemImage: "checkmark.square.fill")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(vertical: 8, horizontal: 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(vertical: 12, horizontal: 16)
            .gradientStyle(.bottomButton)
        }
        .frame(width: 350, height: 500)
        .background(Color.windowBackgroundColor)
        .onReceive(viewModel.dismissPublisher) { _ in
            dismiss()
        }
    }
}
