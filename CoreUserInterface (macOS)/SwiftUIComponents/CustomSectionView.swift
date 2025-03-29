//
//  CustomSectionView.swift
//  RepsCount
//
//  Created by Aleksandr Riakhin on 3/21/25.
//

import SwiftUI

public struct CustomSectionView<Content: View, HeaderTrainingContent: View>: View {

    private var header: LocalizedStringKey
    private var footer: LocalizedStringKey?
    private var content: () -> Content
    private var headerTrailingContent: () -> HeaderTrainingContent

    public init(
        header: LocalizedStringKey,
        footer: LocalizedStringKey? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder headerTrailingContent: @escaping () -> HeaderTrainingContent = { EmptyView() }
    ) {
        self.header = header
        self.footer = footer
        self.content = content
        self.headerTrailingContent = headerTrailingContent
    }

    public var body: some View {
        VStack(spacing: 8) {
            Section {
                content()
            } header: {
                HStack(spacing: 12) {
                    CustomSectionHeader(text: header)
                    headerTrailingContent()
                }
                .textCase(.uppercase)
                .font(.footnote)
                .padding(.horizontal, 12)
            } footer: {
                if let footer {
                    Text(footer)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                }
            }
        }
    }
}
