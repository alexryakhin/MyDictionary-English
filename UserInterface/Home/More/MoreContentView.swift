import SwiftUI
import CoreUserInterface
import CoreNavigation
import Core
import Shared
import UniformTypeIdentifiers

public struct MoreContentView: PageView {

    @Environment(\.requestReview) var requestReview

    public typealias ViewModel = MoreViewModel

    @ObservedObject public var viewModel: ViewModel

    public init(viewModel: MoreViewModel) {
        self.viewModel = viewModel
    }

    public var contentView: some View {
        List {
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
        .navigationTitle("More")
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
                viewModel.errorReceived(error, displayType: .alert)
            }
        }
    }
}
