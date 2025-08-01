//
//  CustomSectionView.swift
//  RepsCount
//
//  Created by Aleksandr Riakhin on 3/21/25.
//

import SwiftUI

struct CustomSectionView<Content: View, HeaderTrainingContent: View>: View {

    private var header: String
    private var footer: String?
    private var content: () -> Content
    private var headerTrailingContent: () -> HeaderTrainingContent

    init(
        header: String,
        footer: String? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder headerTrailingContent: @escaping () -> HeaderTrainingContent = { EmptyView() }
    ) {
        self.header = header
        self.footer = footer
        self.content = content
        self.headerTrailingContent = headerTrailingContent
    }

    var body: some View {
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
