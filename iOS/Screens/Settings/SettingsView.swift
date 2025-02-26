import SwiftUI
import UniformTypeIdentifiers
import Swinject
import SwinjectAutoregistration

struct SettingsView: View {
    @Environment(\.requestReview) var requestReview
    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Review section

                if viewModel.isShowingRating {
                    Section {
                        Button {
                            requestReview()
                        } label: {
                            Label {
                                Text("Rate the app")
                            } icon: {
                                Image(systemName: "star.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.yellow)
                            }
                        }
                    }
                }

                // MARK: - Idioms Tab

                Section {
                    Toggle(isOn: $viewModel.isShowingIdioms) {
                        Text("Showing Idioms Tab")
                    }
                }

                // MARK: - Import & Export

                Section {
                    Button("Import words") {
                        viewModel.isImporting = true
                    }
                    Button("Export words") {
                        viewModel.exportWords()
                    }
                }
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
            .safeAreaInset(edge: .bottom) {
                Text("App version: \(GlobalConstant.currentFullAppVersion)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(16)
            }
            .sheet(item: $viewModel.exportWordsUrl) { url in
                ShareSheet(activityItems: [url])
            }
            .fileImporter(
                isPresented: $viewModel.isImporting,
                allowedContentTypes: [UTType.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        viewModel.importWords(from: url)
                    }
                case .failure(let error):
                    print("❌ File import error: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    DIContainer.shared.resolver ~> SettingsView.self
}
