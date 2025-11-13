//
//  StoryLabLoadingView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 11/13/25.
//

import SwiftUI

struct StoryLabLoadingView: View {

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            AICircularProgressAnimation()
                .frame(maxWidth: 300)

            Text(Loc.StoryLab.Configuration.generating)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(Loc.Quizzes.Loading.preparingNextStory)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .groupedBackground()
    }
}
