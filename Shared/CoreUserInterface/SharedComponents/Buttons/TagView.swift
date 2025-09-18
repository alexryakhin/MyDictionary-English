//
//  TagView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/13/25.
//

import SwiftUI

struct TagView: View {

    enum Size {
        case mini
        case small
        case regular
        case medium
        case large

        var hPadding: CGFloat {
            switch self {
            case .mini: 6
            case .small: 8
            case .regular: 12
            case .medium: 12
            case .large: 16
            }
        }

        var vPadding: CGFloat {
            switch self {
            case .mini: 2
            case .small: 4
            case .regular: 6
            case .medium: 8
            case .large: 12
            }
        }

        var font: Font {
            switch self {
            case .mini: .caption2
            case .small: .system(.caption, design: .rounded, weight: .medium)
            case .regular: .system(.caption, design: .rounded, weight: .medium)
            case .medium: .headline
            case .large: .system(.title2, design: .rounded, weight: .bold)
            }
        }
    }

    enum Style {
        case selected
        case regular
    }

    let text: String
    let systemImage: String?
    let color: Color
    let size: Size
    let style: Style

    init(
        text: String,
        systemImage: String? = nil,
        color: Color,
        size: Size = .regular,
        style: Style = .regular
    ) {
        self.text = text
        self.systemImage = systemImage
        self.color = color
        self.size = size
        self.style = style
    }

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(size.font)
            }
            Text(text)
                .font(size.font)
        }
        .padding(.horizontal, size.hPadding)
        .padding(.vertical, size.vPadding)
        .foregroundStyle(foregroundStyle.gradient)
        .background(backgroundStyle.gradient)
        .glassEffectIfAvailable(.regular, in: .capsule)
        .clipShape(.capsule)
    }

    var foregroundStyle: Color {
        switch style {
        case .selected: .white
        case .regular: color
        }
    }

    var backgroundStyle: Color {
        switch style {
        case .selected: color
        case .regular: color.opacity(0.2)
        }
    }
}
