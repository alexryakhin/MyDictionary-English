//
//  ScrollViewWithCustomNavBar.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct ScrollViewWithCustomNavBar<Content: View, NavigationBar: View>: View {

    private let content: () -> Content
    private let navigationBar: () -> NavigationBar

    @State private var scrollOffset: CGFloat = .zero
    private var navigationBarOpacity: CGFloat {
        min(max(-scrollOffset / 20, 0), 1)
    }

    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder navigationBar: @escaping () -> NavigationBar
    ) {
        self.content = content
        self.navigationBar = navigationBar
    }

    var body: some View {
        ScrollViewWithReader(scrollOffset: $scrollOffset) {
            content()
        }
        .safeAreaInset(edge: .top) {
            navigationBar()
                .background {
                    VStack(spacing: 0) {
                        Color.clear.background(.ultraThinMaterial)
                        Divider()
                    }
                    .opacity(navigationBarOpacity)
                }
        }
    }
}
