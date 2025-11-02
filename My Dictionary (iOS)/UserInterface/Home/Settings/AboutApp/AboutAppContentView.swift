import SwiftUI
import StoreKit

struct AboutAppContentView: View {

    @Environment(\.requestReview) var requestReview

    @StateObject var viewModel = AboutAppViewModel()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - About
                    CustomSectionView(header: Loc.Settings.aboutApp) {
                        VStack(spacing: 24) {
                            Image(.iconRounded)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 128, height: 128)

                            Text(Loc.Settings.aboutAppDescription)
                                .multilineTextAlignment(.leading)

                            HStack(spacing: 8) {
                                Text(Loc.Settings.appVersion)
                                    .bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(GlobalConstant.currentFullAppVersion)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // MARK: - Features
                    CustomSectionView(header: Loc.Settings.features, hPadding: .zero) {
                        FormWithDivider {
                            FeatureRow(text: Loc.Settings.addOrganizeWords)
                            FeatureRow(text: Loc.Settings.practiceQuizzesSpelling)
                            FeatureRow(text: Loc.Settings.trackLearningProgress)
                            FeatureRow(text: Loc.Settings.importExportWordCollection)
                            FeatureRow(text: Loc.Settings.customizeLearningExperience)
                            FeatureRow(text: Loc.Settings.voicePronunciationSupport)
                        }
                    }

                    // MARK: - My Other Apps Section
                    myOtherAppsSection

                    // MARK: - Support section

                    CustomSectionView(header: Loc.Settings.contactMe) {
                        VStack(spacing: 12) {
                            Text(Loc.Settings.contactSupport)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)

                            ActionButton(Loc.Settings.email, systemImage: "envelope") {
                                openEmail()
                                AnalyticsService.shared.logEvent(.emailButtonTapped)
                            }

                            ActionButton(Loc.Settings.instagram, systemImage: "camera") {
                                openURL(GlobalConstant.instagramUrl)
                                AnalyticsService.shared.logEvent(.instagramButtonTapped)
                            }

                            Text(Loc.Coffee.helpfulLearningJourney)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)

                            ActionButton(Loc.Coffee.buyMeACoffee, systemImage: "cup.and.saucer.fill", color: .orange) {
                                openURL(GlobalConstant.buyMeACoffeeUrl)
                                AnalyticsService.shared.logEvent(.buyMeACoffeeTapped)
                            }

                            if viewModel.isShowingRating {
                                ActionButton(Loc.Settings.rateApp, systemImage: "star.fill", color: .yellow) {
                                    requestReview()
                                }
                            }
                        }
                    }
                    .id("Support")
                }
                .padding(vertical: 12, horizontal: 16)
                .if(isPad) { view in
                    view
                        .frame(maxWidth: 550, alignment: .center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .groupedBackground()
            .navigation(
                title: Loc.Navigation.about,
                mode: .large,
                showsBackButton: true,
                trailingContent: {
                    HeaderButton(Loc.Settings.support) {
                        withAnimation {
                            proxy.scrollTo("Support", anchor: .top)
                        }
                    }
                }
            )
            .onAppear {
                AnalyticsService.shared.logEvent(.aboutAppScreenOpened)
            }
        }
    }
    
    // MARK: - My Other Apps Section
    private var myOtherAppsSection: some View {
        CustomSectionView(
            header: Loc.Settings.myOtherApps
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Flippin App
                Button {
                    openFlippin()
                } label: {
                    HStack(spacing: 12) {
                        Image(.flippinIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .clipShape(.rect(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(Loc.Settings.flippinTitle)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Text(Loc.Settings.flippinDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func openFlippin() {
        if let url = URL(string: "https://www.flippin.app") {
            openURL(url)
        }
    }
    
    private func openEmail() {
        if let url = GlobalConstant.emailURL {
            if UIApplication.shared.canOpenURL(url) {
                openURL(url)
            } else {
                showEmailAlert()
            }
        } else {
            showEmailAlert()
        }
    }
    
    private func showEmailAlert() {
        let alert = UIAlertController(
            title: Loc.Settings.emailNotAvailable,
            message: Loc.Settings.pleaseContactMeAt(GlobalConstant.email),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Loc.Actions.copyEmail, style: .default) { _ in
            copyToClipboard(GlobalConstant.email)
        })
        alert.addAction(UIAlertAction(title: Loc.Actions.ok, style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

extension AboutAppContentView {
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
