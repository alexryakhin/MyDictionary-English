import SwiftUI

public extension View {

    func shimmering(
        multiline: Bool = false,
        config: ShimmerConfig = .default
    ) -> some View {
        self.modifier(ShimmerModifier(multiline: multiline, config: config))
    }

    @ViewBuilder
    func shimmering(
        when showShimmer: Bool,
        multiline: Bool = false,
        config: ShimmerConfig = .default
    ) -> some View {
        if showShimmer {
            self.shimmering(multiline: multiline, config: config)
        } else {
            self
        }
    }
}

public extension String {

    static func placeholder(length: Int) -> Self {
        String(repeating: "M", count: length)
    }
}
