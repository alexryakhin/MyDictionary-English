//
//  AdaptiveGradientStyleModifier.swift
//  RepsCount
//
//  Created by Aleksandr Riakhin on 3/16/25.
//

import SwiftUI

struct AdaptiveGradientStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    var color: Color
    var offset: CGFloat
    var interpolation: CGFloat
    var direction: GradientDirection

    func body(content: Content) -> some View {
        content
            .background(color)
            .mask(gradientMask)
    }

    var gradientMask: some View {
        var startPoint = direction.unitPoints.0
        var endPoint = direction.unitPoints.1

        return LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .clear, location: offset),
                .init(color: .black, location: offset+interpolation)
            ],
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

public extension View {
    /// A modifier that applies a gradient blur effect to the view.
    ///
    /// - Parameters:
    ///   - material: Material
    ///   - offset: The distance from the view's edge to where the effect begins, relative to the view's size.
    ///   - interpolation: The distance from the offset to where the effect is fully applied, relative to the view's size.
    ///   - direction: The direction in which the effect is applied.
    func colorWithGradient(
        color: Color = .backgroundColor,
        offset: CGFloat = 0.1,
        interpolation: CGFloat = 0.3,
        direction: GradientDirection = .down
    ) -> some View {
        let offset: CGFloat = min(max(offset, 0), 1)
        let interpolation: CGFloat = min(max(interpolation, 0), 1)

        return modifier(
            AdaptiveGradientStyleModifier(
                color: color,
                offset: offset,
                interpolation: interpolation,
                direction: direction
            )
        )
    }
}
