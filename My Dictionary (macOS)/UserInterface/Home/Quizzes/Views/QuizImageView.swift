//
//  QuizImageView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 9/18/25.
//

import SwiftUI

struct QuizImageView: View {

    @StateObject private var subscriptionService = SubscriptionService.shared

    var localPath: String
    var webUrl: String?

    var body: some View {
        if subscriptionService.isProUser {
            if let image = PexelsService.shared.getImageFromLocalPath(localPath) {
                image
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 12))
                    .frame(maxHeight: 120)
            } else {
                // Fallback to web URL if local fails
                if let webUrl = webUrl, let url = URL(string: webUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(.rect(cornerRadius: 12))
                            .frame(maxHeight: 120)
                    } placeholder: {
                        ShimmerView(height: 120)
                    }
                } else {
                    EmptyView()
                }
            }
        } else {
            EmptyView()
        }
    }
}
