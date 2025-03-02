//
//  ScrollViewWithReader.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 9/8/24.
//

import SwiftUI

struct ScrollViewWithReader<Content: View>: View {
    @Binding private var scrollOffset: CGFloat
    private let axis: Axis.Set
    private let showsIndicators: Bool
    private let content: () -> Content

    init(
        scrollOffset: Binding<CGFloat>,
        axis: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._scrollOffset = scrollOffset
        self.axis = axis
        self.showsIndicators = showsIndicators
        self.content = content
    }
    
    var body: some View {
        ScrollView(axis, showsIndicators: showsIndicators) {
            content()
                .background(GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named(ScrollOffsetPreferenceKey.coordinateSpaceName)).minY
                    )
                })
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }

        }
        .coordinateSpace(name: ScrollOffsetPreferenceKey.coordinateSpaceName)
    }
}

// Preference key for tracking scroll position
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let coordinateSpaceName = "scroll"
    static let defaultValue: CGFloat = .zero

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    }
}
