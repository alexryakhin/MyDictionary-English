//
//  HeaderButtonMenu.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct HeaderButtonMenu<Content: View>: View {

    enum Size {
        case small
        case medium
        case large

        var hPadding: CGFloat {
            switch self {
            case .small: 12
            case .medium: 12
            case .large: 16
            }
        }

        var vPadding: CGFloat {
            switch self {
            case .small: 6
            case .medium: 8
            case .large: 12
            }
        }

        var font: Font {
            switch self {
            case .small: .system(.caption, design: .rounded, weight: .medium)
            case .medium: .system(.subheadline, design: .rounded, weight: .medium)
            case .large: .system(.title2, design: .rounded, weight: .bold)
            }
        }

        var imageSize: CGFloat {
            switch self {
            case .small: 12
            case .medium: 16
            case .large: 20
            }
        }
    }

    enum Style {
        case bordered
        case borderedProminent
    }

    var text: String
    var icon: String?
    var size: Size
    var style: Style
    var color: Color
    var content: () -> Content

    init(
        _ text: String = "",
        icon: String? = nil,
        color: Color = .accent,
        size: Size = .medium,
        style: Style = .bordered,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.text = text
        self.icon = icon
        self.color = color
        self.size = size
        self.style = style
        self.content = content
    }

    var body: some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(size.font)
                        .frame(width: size.imageSize, height: size.imageSize)
                }
                if text.isNotEmpty {
                    Text(text)
                        .font(size.font)
                }
            }
            .padding(.horizontal, size.hPadding)
            .padding(.vertical, size.vPadding)
            .foregroundStyle(foregroundStyle.gradient)
            .background(backgroundStyle.gradient)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut, value: style)
    }

    var foregroundStyle: Color {
        switch style {
        case .borderedProminent: .white
        case .bordered: color
        }
    }

    var backgroundStyle: Color {
        switch style {
        case .borderedProminent: color
        case .bordered: color.opacity(0.2)
        }
    }
}
