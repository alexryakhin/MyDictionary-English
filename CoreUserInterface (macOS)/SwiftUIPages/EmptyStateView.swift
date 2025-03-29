//
//  EmptyStateView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

public struct EmptyStateView: View {

    private let imageSystemName: String?
    private let title: String
    private let subtitle: String?
    private let instructions: String?

    public init(
        imageSystemName: String? = nil,
        title: String,
        subtitle: String? = nil,
        instructions: String? = nil
    ) {
        self.imageSystemName = imageSystemName
        self.title = title
        self.subtitle = subtitle
        self.instructions = instructions
    }

    public var body: some View {
        VStack(spacing: 20) {
            if let imageSystemName {
                Image(systemName: imageSystemName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if let subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)
            }

            if let instructions {
                Text(instructions)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)
            }
        }
        .padding(16)
        .multilineTextAlignment(.center)
    }
}
