//
//  CustomSectionView.swift
//  RepsCount
//
//  Created by Aleksandr Riakhin on 3/21/25.
//

import SwiftUI

struct CustomSectionView<Content: View, TrailingContent: View>: View {

    enum HeaderFontStyle {
        case stealth
        case regular
        case large

        var font: Font {
            switch self {
            case .stealth: .subheadline.weight(.semibold)
            case .regular: .headline.weight(.semibold)
            case .large: .title2.weight(.bold)
            }
        }

        var style: Color {
            switch self {
            case .stealth: .secondary
            case .regular: .primary
            case .large: .primary
            }
        }
    }

    private var header: String
    private var headerFontStyle: HeaderFontStyle
    private var footer: String?
    private var hPadding: CGFloat
    private var content: () -> Content
    private var trailingContent: () -> TrailingContent

    init(
        header: String,
        headerFontStyle: HeaderFontStyle = .regular,
        footer: String? = nil,
        hPadding: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent = { EmptyView() }
    ) {
        self.header = header
        self.headerFontStyle = headerFontStyle
        self.footer = footer
        self.hPadding = hPadding
        self.content = content
        self.trailingContent = trailingContent
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                Text(header)
                    .font(headerFontStyle.font)
                    .foregroundStyle(headerFontStyle.style)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    trailingContent()
                        .fixedSize()
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            content()
                .padding(.horizontal, hPadding)

            if let footer {
                Divider()
                Text(footer)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }
        }
        .padding(.vertical, 16)
        .clippedWithBackground(showShadow: true)
    }
}
