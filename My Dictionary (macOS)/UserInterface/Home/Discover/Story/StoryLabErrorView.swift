//
//  StoryLabErrorView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 11/13/25.
//

import SwiftUI

struct StoryLabErrorView: View {

    var message: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text(Loc.StoryLab.Error.generationFailed)
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .groupedBackground()
    }
}
