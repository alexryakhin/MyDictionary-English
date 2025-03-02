//
//  ButtonStyleConfig.swift
//  Suint One
//
//  Created by Aleksandr Riakhin on 9/30/24.
//
import Foundation
import SwiftUI

enum ButtonStyleConfig {
    case primary, primaryMini, primarySmallHorPadding
    case secondary, secondaryMini
    case tertiary, tertiaryMini
    case dark, darkMini
    case white, whiteMini
    case text, textMini

    var backgroundColor: Color {
        switch self {
        case .primary, .primaryMini, .primarySmallHorPadding: .accentColor
        case .secondary, .secondaryMini: .secondarySystemBackground
        case .tertiary, .tertiaryMini: .tertiarySystemBackground
        case .dark, .darkMini: .darkText
        case .white, .whiteMini: .lightGray
        case .text, .textMini: .clear
        }
    }

    var backgroundPressedColor: Color {
        switch self {
        case .primary, .primaryMini, .primarySmallHorPadding: .accentColor.opacity(0.8)
        case .secondary, .secondaryMini: .secondarySystemFill
        case .tertiary, .tertiaryMini: .accentColor
        case .dark, .darkMini: .secondaryLabel
        case .white, .whiteMini: .lightGray
        case .text, .textMini: .clear
        }
    }

    var backgroundDisabledColor: Color {
        switch self {
        case .primary, .primaryMini, .primarySmallHorPadding: .accentColor.opacity(0.8)
        case .secondary, .secondaryMini: .secondarySystemFill
        case .tertiary, .tertiaryMini: .accentColor
        case .dark, .darkMini: .label
        case .white, .whiteMini: .secondarySystemBackground
        case .text, .textMini: .clear
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary, .primaryMini, .dark, .darkMini, .primarySmallHorPadding: .lightText
        case .secondary, .secondaryMini, .white, .whiteMini: .label
        case .tertiary, .tertiaryMini: .accentColor
        case .text, .textMini: .accentColor
        }
    }

    var foregroundDisabledColor: Color {
        switch self {
        case .primary, .primaryMini, .dark, .darkMini, .primarySmallHorPadding: .darkGray
        case .secondary, .secondaryMini, .white, .whiteMini: .quaternaryLabel
        case .tertiary, .tertiaryMini: .accentColor
        case .text, .textMini: .secondaryLabel
        }
    }

    var font: Font {
        switch self {
        case .primary, .secondary, .tertiary, .dark, .text, .white, .primarySmallHorPadding: .callout
        case .primaryMini, .secondaryMini, .tertiaryMini, .darkMini, .textMini, .whiteMini: .subheadline
        }
    }

    var verPadding: CGFloat {
        switch self {
        case .primary, .secondary, .tertiary, .dark, .white, .text, .primarySmallHorPadding: 16
        case .primaryMini, .secondaryMini, .tertiaryMini, .darkMini, .whiteMini, .textMini: 8
        }
    }

    var horPadding: CGFloat {
        switch self {
        case .primarySmallHorPadding: 4
        default: 16
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .primaryMini, .secondaryMini, .tertiaryMini, .darkMini, .whiteMini, .textMini: 8
        default: 12
        }
    }

    var dashedStrokeColor: Color? {
        switch self {
        default: nil
        }
    }

    func statefulBackgroundColor(isPressed: Bool, isEnabled: Bool) -> Color {
        if !isEnabled { return backgroundDisabledColor }
        if isPressed { return backgroundPressedColor }
        return backgroundColor
    }
}

struct BaseButtonStyle: ButtonStyle {
    private let buttonStyleConfig: ButtonStyleConfig
    private let overrideHorPadding: CGFloat?
    private let overrideVerPadding: CGFloat?
    private let isLoading: Bool

    init(
        buttonStyleConfig: ButtonStyleConfig,
        overrideHorPadding: CGFloat?,
        overrideVerPadding: CGFloat?,
        isLoading: Bool
    ) {
        self.buttonStyleConfig = buttonStyleConfig
        self.overrideHorPadding = overrideHorPadding
        self.overrideVerPadding = overrideVerPadding
        self.isLoading = isLoading
    }

    func makeBody(configuration: Configuration) -> some View {
        BaseButton(
            buttonStyleConfig: buttonStyleConfig,
            configuration: configuration,
            overrideHorPadding: overrideHorPadding,
            overrideVerPadding: overrideVerPadding,
            isLoading: isLoading
        )
    }

    private struct BaseButton: View {

        @Environment(\.isEnabled) private var isEnabled: Bool

        private let configuration: ButtonStyle.Configuration
        private let buttonStyleConfig: ButtonStyleConfig
        private let overrideHorPadding: CGFloat?
        private let overrideVerPadding: CGFloat?
        private let isLoading: Bool

        init(
            buttonStyleConfig: ButtonStyleConfig,
            configuration: ButtonStyle.Configuration,
            overrideHorPadding: CGFloat?,
            overrideVerPadding: CGFloat?,
            isLoading: Bool
        ) {
            self.configuration = configuration
            self.buttonStyleConfig = buttonStyleConfig
            self.overrideHorPadding = overrideHorPadding
            self.overrideVerPadding = overrideVerPadding
            self.isLoading = isLoading
        }

        var body: some View {
            configuration.label
                .font(buttonStyleConfig.font)
                .foregroundColor(isEnabled ? buttonStyleConfig.foregroundColor : buttonStyleConfig.foregroundDisabledColor)
                .tint(isEnabled ? buttonStyleConfig.foregroundColor : buttonStyleConfig.foregroundDisabledColor)
                .opacity(isLoading ? 0 : 1)
                .padding(.horizontal, overrideHorPadding ?? buttonStyleConfig.horPadding)
                .padding(.vertical, overrideVerPadding ?? buttonStyleConfig.verPadding)
                .frame(minWidth: 40)
                .background(buttonStyleConfig.statefulBackgroundColor(isPressed: configuration.isPressed, isEnabled: isEnabled))
                .clipShape(RoundedRectangle(cornerRadius: buttonStyleConfig.cornerRadius))
                .overlay {
                    if isLoading {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    }
                }
                .overlay {
                    if let dashedStrokeColor = buttonStyleConfig.dashedStrokeColor {
                        RoundedRectangle(cornerRadius: buttonStyleConfig.cornerRadius)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundColor(dashedStrokeColor)
                    }
                }
        }
    }
}
