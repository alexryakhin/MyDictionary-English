import SwiftUI

public struct ShimmerConfig {

    let lineHeight: CGFloat
    let lineSpacing: CGFloat
    let baseColor: Color
    let highlightColor: Color
    let cornerRadius: CGFloat
    let animationDuration: TimeInterval
    let highlightMaxWidth: CGFloat
    let lastLineTrailingPadding: CGFloat

    public init(
        lineHeight: CGFloat = 20,
        lineSpacing: CGFloat = 4,
        baseColor: Color = Color.secondary.opacity(0.5),
        highlightColor: Color = Color.secondary.opacity(0.3),
        cornerRadius: CGFloat = 16,
        animationDuration: TimeInterval = 1,
        highlightMaxWidth: CGFloat = 200,
        lastLineTrailingPadding: CGFloat = 80
    ) {
        self.lineHeight = lineHeight
        self.lineSpacing = lineSpacing
        self.baseColor = baseColor
        self.highlightColor = highlightColor
        self.cornerRadius = cornerRadius
        self.animationDuration = animationDuration
        self.highlightMaxWidth = highlightMaxWidth
        self.lastLineTrailingPadding = lastLineTrailingPadding
    }

    public static let `default` = ShimmerConfig()

    public static func custom(
        lineHeight: CGFloat = 20,
        lineSpacing: CGFloat = 4,
        baseColor: Color = Color.secondary.opacity(0.5),
        highlightColor: Color = Color.secondary.opacity(0.3),
        cornerRadius: CGFloat = 16,
        animationDuration: TimeInterval = 1,
        highlightMaxWidth: CGFloat = 200,
        lastLineTrailingPadding: CGFloat = 80
    ) -> Self {
        ShimmerConfig(
            lineHeight: lineHeight,
            lineSpacing: lineSpacing,
            baseColor: baseColor,
            highlightColor: highlightColor,
            cornerRadius: cornerRadius,
            animationDuration: animationDuration,
            highlightMaxWidth: highlightMaxWidth,
            lastLineTrailingPadding: lastLineTrailingPadding
        )
    }
}
