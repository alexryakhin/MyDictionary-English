import SwiftUI

struct AddIdiomView: View {

    @Environment(\.dismiss) var dismiss

    typealias ViewModel = AddIdiomViewModel

    var _viewModel: StateObject<ViewModel>
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    init(inputText: String) {
        _viewModel = StateObject(wrappedValue: ViewModel(inputText: inputText))
    }

    var body: some View {
        ScrollViewWithCustomNavBar {
            VStack(spacing: 16) {
                CustomSectionView(header: "Idiom") {
                    TextField("Idiom", text: _viewModel.projectedValue.inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .clippedWithPaddingAndBackground(.surfaceColor)
                }
                CustomSectionView(header: "Definition") {
                    TextField("Definition", text: _viewModel.projectedValue.inputDefinition, axis: .vertical)
                        .textFieldStyle(.plain)
                        .clippedWithPaddingAndBackground(.surfaceColor)
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
                    AnalyticsService.shared.logEvent(.closeAddIdiomTapped)
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
                AnalyticsService.shared.logEvent(.saveIdiomTapped)
            } label: {
                Label("Save", systemImage: "checkmark.square.fill")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(vertical: 8, horizontal: 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(vertical: 12, horizontal: 16)
            .colorWithGradient(
                offset: 0,
                interpolation: 0.2,
                direction: .down
            )
        }
        .frame(width: 350, height: 500)
        .background(Color.backgroundColor)
        .onReceive(viewModel.dismissPublisher) { _ in
            dismiss()
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.addIdiomOpened)
        }
    }
}
