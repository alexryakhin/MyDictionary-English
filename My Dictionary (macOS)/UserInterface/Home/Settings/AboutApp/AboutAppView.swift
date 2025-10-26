import SwiftUI
import StoreKit

struct AboutAppView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.requestReview) var requestReview

    @StateObject var viewModel = AboutAppViewModel()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
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
                .padding(12)
            }
            .groupedBackground()
            .navigationTitle(Loc.Navigation.about)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(Loc.Settings.support) {
                        withAnimation {
                            proxy.scrollTo("Support", anchor: .top)
                        }
                    }
                }
            }
            .onAppear {
                AnalyticsService.shared.logEvent(.aboutAppScreenOpened)
            }
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
            openURL(url)
        } else {
            showEmailAlert()
        }
    }
    
    private func showEmailAlert() {
        let alert = NSAlert()
        alert.messageText = Loc.Settings.emailNotAvailable
        alert.informativeText = Loc.Settings.pleaseContactMeAt(GlobalConstant.email)
        alert.addButton(withTitle: Loc.Actions.copyEmail)
        alert.addButton(withTitle: Loc.Actions.ok)
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(GlobalConstant.email, forType: .string)
        }
    }
}
