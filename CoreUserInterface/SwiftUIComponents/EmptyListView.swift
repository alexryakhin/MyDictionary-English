//
//  EmptyListView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

public struct EmptyListView<Actions: View>: View {
    private let label: String?
    private let description: String?
    private let background: Color
    private let actions: () -> Actions

    public init(
        label: String? = nil,
        description: String? = nil,
        background: Color = .clear,
        @ViewBuilder actions: @escaping () -> Actions = { EmptyView() }
    ) {
        self.label = label
        self.description = description
        self.background = background
        self.actions = actions
    }

    public var body: some View {
        ZStack {
            background.ignoresSafeArea()
            if #available(iOS 17.0, *) {
                ContentUnavailableView(
                    label: {
                        if let label {
                            Text(label)
                        }
                    },
                    description: {
                        if let description {
                            Text(description)
                        }
                    },
                    actions: actions
                )
            } else {
                VStack(spacing: 12) {
                    if let label {
                        Text(label)
                            .multilineTextAlignment(.center)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    if let description {
                        Text(description)
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    actions()
                }
                .padding(16)
            }
        }
    }
}

#Preview {
    EmptyListView(
        label: "No idioms yet",
        description: "Begin to add idioms to your list by tapping on plus icon in upper left corner",
        background: .background
    )
}
