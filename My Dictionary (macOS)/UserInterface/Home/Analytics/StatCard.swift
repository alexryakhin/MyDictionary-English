//
//  StatCard.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/15/25.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.accent)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clippedWithPaddingAndBackground(
            Color.tertiarySystemGroupedBackground,
            cornerRadius: 16
        )
    }
}
