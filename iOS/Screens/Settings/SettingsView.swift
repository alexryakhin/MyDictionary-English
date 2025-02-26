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
                // MARK: - Idioms Tab

                Section {
                    Toggle(isOn: $viewModel.isShowingIdioms) {
                        Label("Show Idioms Tab", systemImage: "scroll")
                    }
                }

                // MARK: - Import & Export

                Section {
                    Button {
                        viewModel.isImporting = true
                    } label: {
                        Label("Import words", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        viewModel.exportWords()
                    } label: {
                        Label("Export words", systemImage: "square.and.arrow.up")
                    }
                }

                // MARK: - Review section

                Section {
                    Button {
                        UIApplication.shared.open(GlobalConstant.buyMeACoffeeUrl)
                    } label: {
                        Label("Buy Me a Coffee", systemImage: "cup.and.saucer.fill")
                            .foregroundColor(.orange)
                    }
                    if viewModel.isShowingRating {
                        Button {
                            requestReview()
                        } label: {
                            Label("Rate the app", systemImage: "star.fill")
                                .foregroundStyle(Color.yellow)
                        }
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
