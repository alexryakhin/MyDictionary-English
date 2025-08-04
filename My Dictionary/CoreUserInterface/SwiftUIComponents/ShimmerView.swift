import SwiftUI

struct ShimmerView: View {

    private let style: ShimmerConfig
    private var width: CGFloat?
    private var height: CGFloat?

    init(style: ShimmerConfig, width: CGFloat? = nil, height: CGFloat? = nil) {
        self.style = style
        self.width = width
        self.height = height
    }

    init(width: CGFloat? = nil, height: CGFloat? = nil) {
        self.init(style: .default, width: width, height: height)
    }

    var body: some View {
        Color.clear
            .frame(width: width, height: height)
            .shimmering(config: style)
    }
}
