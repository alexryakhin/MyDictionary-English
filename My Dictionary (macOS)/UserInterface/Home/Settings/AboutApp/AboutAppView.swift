import SwiftUI
import StoreKit

struct AboutAppView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.requestReview) var requestReview

    @StateObject var viewModel = AboutAppViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // MARK: - About
                CustomSectionView(header: "About app") {
                    VStack(spacing: 24) {
                        Image(.iconRounded)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 128, height: 128)

                        Text("I created this app because I could not find something that I wanted.\n\nIt is a simple word list manager that allows you to search for words and add their definitions along them without actually translating into a native language.\n\nI find this best to learn English. Hope it will work for you as well.\n\nIf you have any questions, or want to suggest a feature, please reach out to me on the links below. Thank you for using my app!")
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 8) {
                            Text("App version:")
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(GlobalConstant.currentFullAppVersion)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - Features
                CustomSectionView(header: "Features", hPadding: .zero) {
                    FormWithDivider {
                        FeatureRow(text: "Add and organize words with definitions")
                        FeatureRow(text: "Practice with quizzes and spelling exercises")
                        FeatureRow(text: "Track your learning progress")
                        FeatureRow(text: "Import and export your word collection")
                        FeatureRow(text: "Customize your learning experience")
                        FeatureRow(text: "Voice pronunciation support")
                    }
                }

                // MARK: - Follow Me

                CustomSectionView(header: "Contact me") {
                    VStack(spacing: 12) {
                        Text("Have questions, suggestions, or feedback? I'd love to hear from you. Reach out to get support on Instagram or Twitter!")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)

                        ActionButton("X (Twitter)", systemImage: "bird") {
                            openURL(GlobalConstant.twitterUrl)
                            AnalyticsService.shared.logEvent(.twitterButtonTapped)
                        }

                        ActionButton("Instagram", systemImage: "camera") {
                            openURL(GlobalConstant.instagramUrl)
                            AnalyticsService.shared.logEvent(.instagramButtonTapped)
                        }
                    }
                }

                // MARK: - Review section

                CustomSectionView(header: "Support") {
                    VStack(spacing: 12) {
                        ActionButton("Buy Me a Coffee", systemImage: "cup.and.saucer.fill", color: .orange) {
                            openURL(GlobalConstant.buyMeACoffeeUrl)
                            AnalyticsService.shared.logEvent(.buyMeACoffeeTapped)
                        }

                        if viewModel.isShowingRating {
                            ActionButton("Rate the app", systemImage: "star.fill", color: .yellow) {
                                requestReview()
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
        .groupedBackground()
        .navigationTitle("About")
        .onAppear {
            AnalyticsService.shared.logEvent(.aboutAppScreenOpened)
        }
    }
}

extension AboutAppView {
    struct FeatureRow: View {
        let text: String

        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .foregroundStyle(.accent)
                    .font(.system(size: 14))
                Text(text)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .padding(vertical: 12, horizontal: 16)
        }
    }
}
