//
//  View+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

extension View {
    func editModeDisablingLayerView() -> some View {
        self.background(
            VStack {
                Spacer()
                #if os(iOS)
                    .frame(
                        width: UIScreen.width - 32,
                        height: UIScreen.height
                    )
                #elseif os(macOS)
                    .frame(width: 800, height: 600)
                #endif
            }
            .background(Color.black.opacity(0.00000001)) // a hack so clear color would still be touchable
            .editModeDisabling()
        )
    }

    func editModeDisabling() -> some View {
        self
            .onTapGesture {
                endEditing()
            }
    }

    @ViewBuilder func hidden(_ shouldHide: Bool) -> some View {
        switch shouldHide {
        case true: self.hidden()
        case false: self
        }
    }

    func padding(
        vertical: CGFloat,
        horizontal: CGFloat
    ) -> some View {
        self
            .padding(.vertical, vertical)
            .padding(.horizontal, horizontal)
    }

    func backgroundColor(_ color: Color) -> some View {
        self.background(color)
    }

    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        @ViewBuilder transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func ifLet<T, Result: View>(
        _ value: T?,
        @ViewBuilder transform: (Self, T) -> Result
    ) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }

    func onTap(_ onTap: @escaping VoidHandler) -> some View {
        Button {
            onTap()
        } label: {
            self
        }
        .buttonStyle(.plain)
    }

    func errorReceived(title: String = Loc.Errors.error, _ error: Error) {
        Task { @MainActor in
            AlertCenter.shared.showAlert(with: .info(title: title, message: error.localizedDescription))
        }
    }

    func showAlertWithMessage(_ message: String) {
        Task { @MainActor in
            AlertCenter.shared.showAlert(with: .info(title: Loc.Errors.oops, message: message))
        }
    }

    func groupedBackground() -> some View {
        self.background(Color.systemGroupedBackground.ignoresSafeArea())
    }
}

extension Image {
    func frame(sideLength: CGFloat) -> some View {
        self
            .resizable()
            .scaledToFit()
            .frame(width: sideLength, height: sideLength)
    }
}

#if os(iOS)
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

extension View {
    func clippedWithBackground(
        _ color: Color = Color.secondarySystemGroupedBackground,
        in shape: some Shape = RoundedRectangle(cornerRadius: 24),
        showShadow: Bool = false
    ) -> some View {
        self
            .background(color)
            .clipShape(shape)
            .if(showShadow) {
                $0.shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)
            }
    }

    @ViewBuilder
    func clippedWithBackgroundMaterial(
        _ material: Material = .thinMaterial,
        in shape: some Shape = RoundedRectangle(cornerRadius: 24),
        showShadow: Bool = false
    ) -> some View {
        self
            .background(material)
            .clipShape(shape)
            .if(showShadow) {
                $0.shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)
            }
    }

    func clippedWithPaddingAndBackground(
        _ color: Color = Color.secondarySystemGroupedBackground,
        in shape: some Shape = RoundedRectangle(cornerRadius: 24),
        showShadow: Bool = false
    ) -> some View {
        self
            .padding(16)
            .background(color)
            .clipShape(shape)
            .if(showShadow) {
                $0.shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)
            }
    }

    @ViewBuilder
    func clippedWithPaddingAndBackgroundMaterial(
        _ material: Material = .thinMaterial,
        in shape: some Shape = RoundedRectangle(cornerRadius: 24),
        showShadow: Bool = false
    ) -> some View {
        self
            .padding(16)
            .background(material)
            .clipShape(shape)
            .if(showShadow) {
                $0.shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)
            }
    }

    func withGradientBackground(_ color: Color = .accentColor) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    color.opacity(0.15),
                    color.opacity(0.1),
                    Color.systemBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            self
        }
    }
}

func endEditing() {
    #if os(iOS)
    UIApplication.shared.endEditing()
    #elseif os(macOS)
    NSApplication.shared.keyWindow?.makeFirstResponder(nil)
    #endif
}

func copyToClipboard(_ string: String) {
    #if os(iOS)
    UIPasteboard.general.string = string
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(string, forType: .string)
    #endif
}

func openURL(_ url: URL) {
    #if os(iOS)
    UIApplication.shared.open(url)
    #elseif os(macOS)
    NSWorkspace.shared.open(url)
    #endif
}

extension View {
    @ViewBuilder
    func safeAreaBarIfAvailable<Content: View>(
        edge: VerticalEdge = .bottom,
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat = .zero,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self
                .safeAreaBar(edge: edge, alignment: alignment, spacing: spacing, content: content)
        } else {
            self
                .safeAreaInset(edge: edge, alignment: alignment, spacing: spacing, content: content)
        }
    }

    @ViewBuilder
    func materialBackgroundIfNoGlassAvailable(_ material: Material = .ultraThinMaterial) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self
        } else {
            self.background(material)
        }
    }
}

enum GlassEffect {
    case regular
    case clear
    case identity
    case tint(Color?)
    case interactive(Bool)

    @available(macOS 26.0, *)
    @available(iOS 26.0, *)
    var glass: Glass {
        switch self {
        case .regular:
            return .regular
        case .clear:
            return .clear
        case .identity:
            return .identity
        case .tint(let color):
            return Glass.regular.tint(color)
        case let .interactive(isEnabled):
            return Glass.regular.interactive(isEnabled)
        }
    }
}

extension View {
    @ViewBuilder
    func glassEffectIfAvailable(
        _ glass: GlassEffect = .regular,
        in shape: some Shape = RoundedRectangle(cornerRadius: 16)
    ) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffect(glass.glass, in: shape)
        } else {
            self
        }
    }

    @ViewBuilder
    func glassBackgroundEffectIfAvailable(
        _ glass: GlassEffect = .regular,
        in shape: some Shape = RoundedRectangle(cornerRadius: 16)
    ) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self
                .background(
                    Color.clear
                        .glassEffect(glass.glass, in: shape)
                )
        } else {
            self
        }
    }

    @ViewBuilder
    func glassEffectIfAvailableWithBackup(
        _ glass: GlassEffect = .regular,
        in shape: some Shape = RoundedRectangle(cornerRadius: 16)
    ) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self
                .glassEffect(glass.glass, in: shape)
                .clipShape(shape)
        } else {
            self
                .clippedWithBackgroundMaterial(.regular, in: shape)
        }
    }

    @ViewBuilder
    func glassBackgroundEffectIfAvailableWithBackup(
        _ glass: GlassEffect = .regular,
        in shape: some Shape = RoundedRectangle(cornerRadius: 16)
    ) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self
                .background(
                    Color.clear
                        .glassEffect(glass.glass, in: shape)
                )
                .clipShape(shape)
        } else {
            self
                .clippedWithBackgroundMaterial(.regular, in: shape)
        }
    }
}

var isGlassAvailable: Bool {
    if #available(iOS 26.0, macOS 26.0, *) {
        return true
    } else {
        return false
    }
}
