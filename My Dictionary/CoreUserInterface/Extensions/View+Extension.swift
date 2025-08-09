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
                    .frame(
                        width: UIScreen.width - 32,
                        height: UIScreen.height
                    )
            }
                .background(Color.black.opacity(0.00000001)) // a hack so clear color would still be touchable
                .editModeDisabling()
        )
    }

    func editModeDisabling() -> some View {
        self
            .onTapGesture {
                UIApplication.shared.endEditing()
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
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func ifLet<T, Result: View>(_ value: T?, transform: (Self, T) -> Result) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }

    func onTap(_ onTap: @escaping () -> Void) -> some View {
        Button {
            onTap()
        } label: {
            self
        }
    }

    func errorReceived(title: String = "Error", _ error: Error) {
        AlertCenter.shared.showAlert(with: .error(title: title, message: error.localizedDescription))
    }

    func showAlertWithMessage(_ message: String) {
        AlertCenter.shared.showAlert(with: .error(title: "Ooops!", message: message))
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

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
    func clippedWithBackground(
        _ color: Color = Color(.secondarySystemGroupedBackground),
        cornerRadius: CGFloat = 24,
        showShadow: Bool = false
    ) -> some View {
        self
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .if(showShadow) {
                $0.shadow(color: Color(.separator), radius: 2)
            }
    }

    func clippedWithBackgroundMaterial(
        _ material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = 24,
        showShadow: Bool = false
    ) -> some View {
        self
            .background(material)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .if(showShadow) {
                $0.shadow(color: Color(.separator), radius: 2)
            }
    }

    func clippedWithPaddingAndBackground(
        _ color: Color = Color(.secondarySystemGroupedBackground),
        cornerRadius: CGFloat = 24,
        showShadow: Bool = false
    ) -> some View {
        self
            .padding(16)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .if(showShadow) {
                $0.shadow(color: Color(.separator), radius: 2)
            }
    }

    func clippedWithPaddingAndBackgroundMaterial(
        _ material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = 24,
        showShadow: Bool = false
    ) -> some View {
        self
            .padding(16)
            .background(material)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .if(showShadow) {
                $0.shadow(color: Color(.separator), radius: 2)
            }
    }
}
