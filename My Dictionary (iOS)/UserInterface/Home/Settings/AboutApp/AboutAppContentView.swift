import SwiftUI
import StoreKit

struct AboutAppContentView: View {

    @Environment(\.requestReview) var requestReview

    @StateObject var viewModel = AboutAppViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - About
                CustomSectionView(header: Loc.Settings.aboutApp.localized) {
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
                CustomSectionView(header: Loc.Settings.features.localized, hPadding: .zero) {
                    FormWithDivider {
                        FeatureRow(text: Loc.Settings.addOrganizeWords.localized)
                        FeatureRow(text: Loc.Settings.practiceQuizzesSpelling.localized)
                        FeatureRow(text: Loc.Settings.trackLearningProgress.localized)
                        FeatureRow(text: Loc.Settings.importExportWordCollection.localized)
                        FeatureRow(text: Loc.Settings.customizeLearningExperience.localized)
                        FeatureRow(text: Loc.Settings.voicePronunciationSupport.localized)
                    }
                }

                // MARK: - Follow Me

                CustomSectionView(header: Loc.Settings.contactMe.localized) {
                    VStack(spacing: 12) {
                        Text(Loc.Settings.contactSupport.localized)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)

                        ActionButton(Loc.Settings.xTwitter.localized, systemImage: "bird") {
                            openURL(GlobalConstant.twitterUrl)
                            AnalyticsService.shared.logEvent(.twitterButtonTapped)
                        }

                        ActionButton(Loc.Settings.instagram.localized, systemImage: "camera") {
                            openURL(GlobalConstant.instagramUrl)
                            AnalyticsService.shared.logEvent(.instagramButtonTapped)
                        }
                    }
                }

                // MARK: - Review section

                CustomSectionView(header: Loc.Settings.support.localized) {
                    VStack(spacing: 12) {
                        ActionButton(Loc.Coffee.buyMeACoffee.localized, systemImage: "cup.and.saucer.fill", color: .orange) {
                            openURL(GlobalConstant.buyMeACoffeeUrl)
                            AnalyticsService.shared.logEvent(.buyMeACoffeeTapped)
                        }

                        if viewModel.isShowingRating {
                            ActionButton(Loc.Settings.rateApp.localized, systemImage: "star.fill", color: .yellow) {
                                requestReview()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .groupedBackground()
        .navigation(title: Loc.Navigation.about.localized, mode: .large, showsBackButton: true)
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
