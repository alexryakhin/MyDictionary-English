import SwiftUI
import Core
import CoreUserInterface__macOS_
import Shared

struct DictionarySettings: PageView {
    typealias ViewModel = SettingsViewModel

    @Environment(\.requestReview) var requestReview

    var _viewModel = StateObject(wrappedValue: ViewModel())
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    var contentView: some View {
        Form {
            Button {
                requestReview()
            } label: {
                Text("Review the app")
            }
        }
        .frame(width: 300)
        .navigationTitle("Dictionary Settings")
        .padding(80)
    }
}

#Preview {
    DictionarySettings()
}
