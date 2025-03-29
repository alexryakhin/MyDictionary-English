import SwiftUI

struct DictionarySettings: View {
    @Environment(\.requestReview) var requestReview

    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
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
