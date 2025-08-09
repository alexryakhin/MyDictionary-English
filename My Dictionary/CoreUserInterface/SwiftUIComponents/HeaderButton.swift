//
//  HeaderButton.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct HeaderButton: View {

    enum Style {
        case bordered
        case borderedProminent
    }

    var text: String
    var icon: String?
    var style: Style
    var font: Font
    var action: () -> Void

    init(
        text: String = "",
        icon: String? = nil,
        style: Style = .bordered,
        font: Font = .footnote,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.icon = icon
        self.style = style
        self.font = font
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            if let icon {
                if text.isEmpty {
                    Image(systemName: icon)
                        .frame(width: 16, height: 16)
                } else {
                    Label(text, systemImage: icon)
                        .font(font)
                }
            } else {
                Text(text)
                    .font(font)
            }
        }
        .if(style == .bordered) {
            $0.buttonStyle(.bordered)
        }
        .if(style == .borderedProminent) {
            $0.buttonStyle(.borderedProminent)
        }
        .clipShape(Capsule())
    }
}
