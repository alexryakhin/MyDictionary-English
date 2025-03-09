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
            // MARK: - About

            Section {
                Text("I created this app because I could not find something that I wanted. It is a simple word list manager that allows you to search for words and add their definitions along them without actually translating into a native language. I find this best to learn English. Hope it will work for you as well. If you have any questions, or want to suggest a feature, please reach out to me on the links below. Thank you for using my app!")
                    .multilineTextAlignment(.leading)
                HStack(spacing: 8) {
                    Text("App version:")
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(GlobalConstant.currentFullAppVersion)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("About")
            }

            // MARK: - Follow Me

            Section {
                Button {
                    UIApplication.shared.open(GlobalConstant.twitterUrl)
                } label: {
                    Label("Follow on X", systemImage: "bird")
                }
                Button {
                    UIApplication.shared.open(GlobalConstant.instagramUrl)
                } label: {
                    Label("Follow on Instagram", systemImage: "camera")
                }
            } header: {
                Text("Follow Me")
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
            } header: {
                Text("Support")
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
            } header: {
                Text("Import / Export")
            } footer: {
                Text("Please note that import and export only work with files created by this app.")
            }
        }
        .listStyle(.insetGrouped)
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
