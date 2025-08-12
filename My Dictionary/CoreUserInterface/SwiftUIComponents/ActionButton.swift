//
//  HeaderButton.swift
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
    var style: Style
    var font: Font
    var isLoading: Bool
    var action: () -> Void

    init(
        _ text: String,
        systemImage: String? = nil,
        style: Style = .bordered,
        font: Font = .headline,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.systemImage = systemImage
        self.style = style
        self.font = font
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            if let systemImage {
                Label(text, systemImage: systemImage)
                    .font(font)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .opacity(isLoading ? 0 : 1)
                    .overlay {
                        if isLoading {
                            ProgressView()
                        }
                    }
            } else {
                Text(text)
                    .font(font)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .opacity(isLoading ? 0 : 1)
                    .overlay {
                        if isLoading {
                            ProgressView()
                        }
                    }
            }
        }
        .if(style == .bordered) {
            $0.buttonStyle(.bordered)
        }
        .if(style == .borderedProminent) {
            $0.buttonStyle(.borderedProminent)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .allowsHitTesting(!isLoading)
    }
}
