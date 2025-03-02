//
//  View+Extension.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 10/6/24.
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

    @ViewBuilder func hidden(_ shouldHide: Bool) -> some View {
        switch shouldHide {
        case true: self.hidden()
        case false: self
        }
    }

    func padding(
        vertical: CGFloat = 0,
        horizontal: CGFloat = 0
    ) -> some View {
        self
            .padding(.vertical, vertical)
            .padding(.horizontal, horizontal)
    }

    func padding(
        top: CGFloat = 0,
        leading: CGFloat = 0,
        bottom: CGFloat = 0,
        trailing: CGFloat = 0
    ) -> some View {
        self
            .padding(.top, top)
            .padding(.leading, leading)
            .padding(.bottom, bottom)
            .padding(.trailing, trailing)
    }

    func backgroundColor(_ color: Color) -> some View {
        self.background(color)
    }

    /// Removing keyboard on tap
    func editModeDisabling() -> some View {
        self
            .onTapGesture {
                UIApplication.shared.endEditing()
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

    @ViewBuilder
    func `if`<Result: View>(_ condition: Bool, transform: (Self) -> Result) -> some View {
        if condition {
            transform(self)
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

