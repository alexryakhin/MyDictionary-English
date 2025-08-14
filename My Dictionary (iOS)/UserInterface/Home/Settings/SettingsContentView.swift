import SwiftUI
import UniformTypeIdentifiers
import StoreKit
import FirebaseAuth

struct SettingsContentView: View {

    @ObservedObject var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        SettingsView(viewModel: viewModel)
    }
}
