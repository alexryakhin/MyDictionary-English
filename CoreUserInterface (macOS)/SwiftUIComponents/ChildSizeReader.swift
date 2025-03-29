import SwiftUI

public struct ChildSizeReader<Content: View>: View {
    @Binding private var size: CGSize
    private let content: () -> Content

    public init(
        size: Binding<CGSize>,
        content: @escaping () -> Content
    ) {
        self._size = size
        self.content = content
    }

    public var body: some View {
        ZStack {
            content()
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: SizePreferenceKey.self, value: proxy.size)
                    }
                )
        }
        .onPreferenceChange(SizePreferenceKey.self) { preferences in
            self.size = preferences
        }
    }
}

private struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize
    static let defaultValue: Value = .zero

    static func reduce(value _: inout Value, nextValue: () -> Value) {
        _ = nextValue()
    }
}
