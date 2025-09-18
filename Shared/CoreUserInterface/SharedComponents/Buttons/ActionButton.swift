//
//  ActionButton.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct ActionButton: View {

    enum Style {
        case bordered
        case borderedProminent
    }

    var text: String
    var systemImage: String?
    var color: Color
    var style: Style
    var action: VoidHandler

    init(
        _ text: String,
        systemImage: String? = nil,
        color: Color = .accent,
        style: Style = .bordered,
        action: @escaping VoidHandler
    ) {
        self.text = text
        self.systemImage = systemImage
        self.color = color
        self.style = style
        self.action = action
    }

    var body: some View {
        Button {
            HapticManager.shared.triggerImpact(style: .medium)
            action()
        } label: {
            HStack(spacing: 12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(font)
                        .frame(width: 16, height: 16)
                }
                Text(text)
                    .font(font)
                    .multilineTextAlignment(systemImage == nil ? .center : .leading)
            }
            .padding(vertical: 12, horizontal: 16)
            .foregroundStyle(foregroundStyle.gradient)
            .frame(maxWidth: .infinity)
            .background(backgroundStyle.gradient)
            .glassEffectIfAvailable(.regular, in: .rect(cornerRadius: 16))
            .clipShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
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

    var font: Font {
        switch style {
        case .borderedProminent: .headline
        case .bordered: .subheadline
        }
    }
}
