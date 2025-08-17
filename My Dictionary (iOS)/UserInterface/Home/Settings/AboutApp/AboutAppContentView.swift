import SwiftUI
import StoreKit

struct AboutAppContentView: View {

    @Environment(\.requestReview) var requestReview

    @StateObject var viewModel = AboutAppViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - About
                CustomSectionView(header: "About app") {
                    VStack(spacing: 24) {
                        Image(.iconRounded)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 128, height: 128)

                        Text(Loc.Settings.aboutAppDescription.localized)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 8) {
                            Text(Loc.Settings.appVersion.localized)
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
                        Text(Loc.Settings.contactSupport.localized)
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
            .padding(.horizontal, 16)
        }
        .groupedBackground()
        .navigation(title: "About", mode: .large, showsBackButton: true)
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
