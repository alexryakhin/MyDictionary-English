import SwiftUI

struct ShimmerModifier: ViewModifier {

    @State private var moveTo: CGFloat = -1

    private let config: ShimmerConfig
    private let multiline: Bool

    init(multiline: Bool, config: ShimmerConfig) {
        self.multiline = multiline
        self.config = config
    }

    func body(content: Content) -> some View {
        content
            .hidden()
            .overlay {
                GeometryReader { geometry in
                    let size = geometry.size
                    if multiline {
                        shimmerLinesBlock(size: size)
                    } else {
                        shimmerBlock(width: size.width)
                    }
                }
            }
            .onAppear {
                moveTo = 1.0
            }
            .animation(
                .linear(duration: config.animationDuration).repeatForever(autoreverses: false),
                value: moveTo
            )
    }

    @ViewBuilder
    private func shimmerBlock(width: CGFloat, trailingPadding: CGFloat = 0) -> some View {
        config.baseColor
            .overlay {
                Rectangle()
                    .fill(config.highlightColor)
                    .mask {
                        Rectangle()
                            .fill(
                                .linearGradient(
                                    colors: [
                                        .white.opacity(0),
                                        .white.opacity(1),
                                        .white.opacity(0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: min(config.highlightMaxWidth, width))
                            .offset(x: width * moveTo)
                            .padding(.leading, trailingPadding)
                    }
            }
            .cornerRadius(config.cornerRadius)
            .padding(.trailing, trailingPadding)
    }

    @ViewBuilder
    private func shimmerLinesBlock(size: CGSize) -> some View {
        let linesCount = linesCount(forHeight: size.height)
        if linesCount > 1 {
            VStack(alignment: .leading, spacing: config.lineSpacing) {
                ForEach(0...linesCount, id: \.self) { offset in
                    if offset == linesCount {
                        shimmerBlock(width: size.width, trailingPadding: config.lastLineTrailingPadding)
                    } else {
                        shimmerBlock(width: size.width)
                    }
                }
            }
        } else {
            shimmerBlock(width: size.width)
        }
    }

    private func linesCount(forHeight height: CGFloat) -> Int {
        let count = Int((height + config.lineSpacing) / (config.lineHeight + config.lineSpacing))
        return count
    }
}

#Preview {
    VStack {
        Text(verbatim: .placeholder(length: 20))
            .shimmering()
        Color.red
            .frame(width: 200, height: 60)
            .shimmering()
        ZStack {
            Color.green
            Text("AB")
        }
        .frame(width: 56, height: 56)
        .shimmering()
        .clipShape(Circle())
        Text(verbatim: .placeholder(length: 400))
            .shimmering(multiline: true)
            .padding(.horizontal, 32)
    }
}
