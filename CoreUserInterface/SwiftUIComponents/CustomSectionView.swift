//
//  CustomSectionView.swift
//  RepsCount
//
//  Created by Aleksandr Riakhin on 3/21/25.
//

import SwiftUI

public struct CustomSectionView<Content: View, HeaderTrainingContent: View>: View {

    private var header: LocalizedStringKey
    private var headerTrailingContent: () -> HeaderTrainingContent
    private var content: () -> Content

    public init(
        header: LocalizedStringKey,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder headerTrailingContent: @escaping () -> HeaderTrainingContent = { EmptyView() }
    ) {
        self.header = header
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
            }
        }
    }
}
