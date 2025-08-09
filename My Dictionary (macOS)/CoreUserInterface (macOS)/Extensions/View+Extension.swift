//
//  View+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

extension View {
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

    func backgroundMaterial(_ material: Material) -> some View {
        self.background(material)
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
        .buttonStyle(.borderless)
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

extension View {
    func clippedWithBackground(_ color: Color = Color(.secondarySystemFill)) -> some View {
        self
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func clippedWithBackgroundMaterial(_ material: Material = .ultraThinMaterial) -> some View {
        self
            .background(material)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func clippedWithPaddingAndBackground(padding: CGFloat = 16, color: Color = Color(.secondarySystemFill)) -> some View {
        self
            .padding(padding)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func clippedWithPaddingAndBackgroundMaterial(padding: CGFloat = 16, material: Material = .ultraThinMaterial) -> some View {
        self
            .padding(padding)
            .background(material)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
