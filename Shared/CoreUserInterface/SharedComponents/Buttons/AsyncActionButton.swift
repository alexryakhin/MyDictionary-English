//
//  AsyncActionButton.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct AsyncActionButton: View {

    enum Style {
        case bordered
        case borderedProminent
    }

    private let text: String
    private let systemImage: String?
    private let color: Color
    private let style: Style
    private let action: AsyncVoidHandler

    @State private var isLoading: Bool = false

    init(
        _ text: String,
        systemImage: String? = nil,
        color: Color = .accent,
        style: Style = .bordered,
        action: @escaping AsyncVoidHandler
    ) {
        self.text = text
        self.systemImage = systemImage
        self.color = color
        self.style = style
        self.action = action
    }

    var body: some View {
        Button {
            Task { @MainActor in
                HapticManager.shared.triggerImpact(style: .soft)
                isLoading = true
                defer { isLoading = false }
                do {
                    try await action()
                    HapticManager.shared.triggerNotification(type: .success)
                } catch {
                    errorReceived(error)
                }
            }
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
            .opacity(isLoading ? 0 : 1)
            .frame(maxWidth: .infinity)
            .background(backgroundStyle.gradient)
            .overlay {
                if isLoading {
                    LoaderView(color: foregroundStyle)
                        .frame(width: 16, height: 16)
                }
            }
            .glassEffectIfAvailable(in: .rect(cornerRadius: 16))
            .clipShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!isLoading)
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
