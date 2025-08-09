import SwiftUI
import StoreKit

struct AboutAppContentView: View {

    @Environment(\.requestReview) var requestReview

    @StateObject var viewModel = AboutAppViewModel()

    var body: some View {
        List {
            // MARK: - About
            Section {
                Text("I created this app because I could not find something that I wanted.\n\nIt is a simple word list manager that allows you to search for words and add their definitions along them without actually translating into a native language.\n\nI find this best to learn English. Hope it will work for you as well.\n\nIf you have any questions, or want to suggest a feature, please reach out to me on the links below. Thank you for using my app!")
                    .multilineTextAlignment(.leading)
                HStack(spacing: 8) {
                    Text("App version:")
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(GlobalConstant.currentFullAppVersion)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("About app")
            }

            // MARK: - Features
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(text: "Add and organize words with definitions")
                    FeatureRow(text: "Practice with quizzes and spelling exercises")
                    FeatureRow(text: "Track your learning progress")
                    FeatureRow(text: "Import and export your word collection")
                    FeatureRow(text: "Customize your learning experience")
                    FeatureRow(text: "Voice pronunciation support")
                }
            } header: {
                Text("Features")
            }

            // MARK: - Follow Me

            Section {
                Text("Have questions, suggestions, or feedback? I'd love to hear from you. Reach out to get support on Instagram or Twitter!")
                Button {
                    UIApplication.shared.open(GlobalConstant.twitterUrl)
                    AnalyticsService.shared.logEvent(.twitterButtonTapped)
                } label: {
                    Label("X (Twitter)", systemImage: "bird")
                }
                Button {
                    UIApplication.shared.open(GlobalConstant.instagramUrl)
                    AnalyticsService.shared.logEvent(.instagramButtonTapped)
                } label: {
                    Label("Instagram", systemImage: "camera")
                }
            } header: {
                Text("Contact me")
            }

            // MARK: - Review section

            Section {
                Button {
                    UIApplication.shared.open(GlobalConstant.buyMeACoffeeUrl)
                    AnalyticsService.shared.logEvent(.buyMeACoffeeTapped)
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
        }
        .listStyle(.insetGrouped)
        .navigation(title: "About", mode: .large)
        .onAppear {
            AnalyticsService.shared.logEvent(.aboutAppScreenOpened)
        }
    }
}

struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .foregroundColor(.blue)
                .font(.system(size: 14))
            Text(text)
                .font(.body)
        }
    }
}
