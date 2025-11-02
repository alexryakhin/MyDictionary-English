//
//  BannerView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/30/25.
//

import SwiftUI

struct BannerView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let buttonTitle: String
    let buttonAction: () -> Void

    init(
        icon: String,
        iconColor: Color = .accent,
        title: String,
        message: String,
        buttonTitle: String,
        buttonAction: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)

                    HeaderButton(buttonTitle, style: .borderedProminent) {
                        buttonAction()
                    }
                    .padding(.top, 8)
                }
                Spacer()
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(iconColor.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(iconColor.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

// MARK: - Convenience Initializers

extension BannerView {
    /// Creates an AI upgrade banner
    static func aiUpgrade() -> BannerView {
        BannerView(
            icon: "sparkles",
            iconColor: .accent,
            title: Loc.Subscription.Paywall.upgradeToPro,
            message: Loc.Ai.AiError.proRequired,
            buttonTitle: Loc.Actions.upgrade
        ) {
            PaywallService.shared.presentPaywall(for: .aiDefinitions)
        }
    }
}
