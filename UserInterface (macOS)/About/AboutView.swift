//
//  AboutView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 4/1/25.
//

import SwiftUI
import StoreKit

struct AboutView: View {

    @AppStorage(UDKeys.isShowingRating) var isShowingRating: Bool = true
    @Environment(\.openURL) var openURL
    @Environment(\.requestReview) var requestReview

    init() {}

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                aboutSectionView
                contactMeSectionView
                supportSectionView
            }
            .padding(vertical: 12, horizontal: 16)
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.aboutAppScreenOpened)
        }
        .frame(width: 500, height: 700)
        .fixedSize()
    }

    // MARK: - About
    private var aboutSectionView: some View {
        CustomSectionView(header: "About app") {
            FormWithDivider {
                CellWrapper {
                    Text("I created this app because I could not find something that I wanted.\n\nIt is a simple word list manager that allows you to search for words and add their definitions along them without actually translating into a native language.\n\nI find this best to learn English. Hope it will work for you as well.\n\nIf you have any questions, or want to suggest a feature, please reach out to me on the links below. Thank you for using my app!")
                        .multilineTextAlignment(.leading)
                }
                CellWrapper {
                    HStack(spacing: 8) {
                        Text("App version:")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(GlobalConstant.currentFullAppVersion)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .clippedWithBackground()
        }
    }

    // MARK: - Contact me
    private var contactMeSectionView: some View {
        CustomSectionView(header: "Contact me") {
            FormWithDivider {
                CellWrapper {
                    Text("Have questions, suggestions, or feedback? I'd love to hear from you. Reach out to get support on Instagram or Twitter!")
                }
                ListButton("X (Twitter)", systemImage: "bird") {
                    openURL(GlobalConstant.twitterUrl)
                    AnalyticsService.shared.logEvent(.twitterButtonTapped)
                }
                ListButton("Instagram", systemImage: "camera") {
                    openURL(GlobalConstant.instagramUrl)
                    AnalyticsService.shared.logEvent(.instagramButtonTapped)
                }
            }
            .clippedWithBackground()
        }
    }

    // MARK: - Support section
    private var supportSectionView: some View {
        CustomSectionView(header: "Support") {
            FormWithDivider {
                ListButton("Buy Me a Coffee", systemImage: "cup.and.saucer.fill", foregroundColor: .orange) {
                    openURL(GlobalConstant.buyMeACoffeeUrl)
                    AnalyticsService.shared.logEvent(.buyMeACoffeeTapped)
                }
                if isShowingRating {
                    ListButton("Rate the app", systemImage: "star.fill", foregroundColor: .yellow) {
                        requestReview()
                        AnalyticsService.shared.logEvent(.requestReviewTapped)
                    }
                }
            }
            .clippedWithBackground()
        }
    }
}
